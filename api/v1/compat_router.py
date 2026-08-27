"""Flutter compatibility routes backed by the canonical Hajeen Brain runtime."""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
import base64
import binascii
from fastapi.responses import StreamingResponse

from api.v1.ai.router import ChatRequestSchema, chat, chat_stream

router = APIRouter(tags=["Flutter compatibility"])
_CONVERSATIONS: Dict[str, Dict[str, Any]] = {}
_MESSAGES: Dict[str, List[Dict[str, Any]]] = {}
_FILES: Dict[str, Dict[str, Any]] = {}


def _scope(request: Request) -> str:
    """Return a stable, account-specific scope without storing raw bearer tokens."""
    authorization = request.headers.get("authorization", "").strip()
    if not authorization:
        return "anonymous"
    token = authorization.split(" ", 1)[1] if " " in authorization else authorization
    # JWTs can rotate while the account stays the same. Prefer their stable
    # subject/email claim; opaque tokens fall back to a token-derived scope.
    parts = token.split(".")
    if len(parts) == 3:
        try:
            payload = parts[1] + ("=" * (-len(parts[1]) % 4))
            claims = json.loads(base64.urlsafe_b64decode(payload).decode("utf-8"))
            identity = claims.get("sub") or claims.get("user_id") or claims.get("email")
            if identity:
                return f"account:{str(identity).strip().lower()}"
        except (ValueError, UnicodeDecodeError, json.JSONDecodeError, binascii.Error):
            pass
    return f"token:{token}"


def _owned_conversation(conversation_id: str, request: Request) -> Dict[str, Any]:
    item = _CONVERSATIONS.get(conversation_id)
    if item is None or item.get("metadata", {}).get("scope") != _scope(request):
        raise HTTPException(404, "المحادثة غير موجودة")
    return item


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _conversation(conversation_id: str, title: str = "محادثة جديدة") -> Dict[str, Any]:
    timestamp = _now()
    return {
        "id": conversation_id,
        "title": title,
        "createdAt": timestamp,
        "updatedAt": timestamp,
        "status": "active",
        "lastMessageSnippet": None,
        "aiModelId": "groq/openai/gpt-oss-20b",
        "metadata": {"provider": "groq", "runtime": "HajeenBrainV3"},
    }


@router.get("/conversations")
async def list_conversations(request: Request) -> List[Dict[str, Any]]:
    scope = _scope(request)
    return [item for item in _CONVERSATIONS.values() if item.get("metadata", {}).get("scope") == scope]


@router.post("/conversations")
async def create_conversation(body: Dict[str, Any], request: Request) -> Dict[str, Any]:
    conversation_id = str(uuid.uuid4())
    item = _conversation(conversation_id, str(body.get("title") or "محادثة جديدة"))
    item["metadata"]["scope"] = _scope(request)
    _CONVERSATIONS[conversation_id] = item
    _MESSAGES[conversation_id] = []
    return item


@router.patch("/conversations/{conversation_id}")
async def update_conversation(conversation_id: str, body: Dict[str, Any], request: Request) -> Dict[str, Any]:
    item = _owned_conversation(conversation_id, request)
    if body.get("title"):
        item["title"] = str(body["title"])
    item["updatedAt"] = _now()
    return item


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str, request: Request) -> Dict[str, Any]:
    _owned_conversation(conversation_id, request)
    _CONVERSATIONS.pop(conversation_id, None)
    _MESSAGES.pop(conversation_id, None)
    return {"success": True}


@router.get("/conversations/{conversation_id}/messages")
async def list_messages(conversation_id: str, request: Request) -> List[Dict[str, Any]]:
    _owned_conversation(conversation_id, request)
    return _MESSAGES.get(conversation_id, [])


@router.post("/conversations/{conversation_id}/messages")
async def create_message(conversation_id: str, body: Dict[str, Any], request: Request) -> Dict[str, Any]:
    _owned_conversation(conversation_id, request)
    content = str(body.get("content") or body.get("message") or "").strip()
    attachments = body.get("attachments") if isinstance(body.get("attachments"), list) else []
    if not content and not attachments:
        raise HTTPException(422, "نص الرسالة أو المرفق مطلوب")
    _MESSAGES[conversation_id].append(_message(conversation_id, "user", content, attachments=attachments))
    item = _CONVERSATIONS[conversation_id]
    if item["title"] == "محادثة جديدة":
        item["title"] = _title_from_message(content, attachments)
    result = await chat(_chat_request(content, conversation_id, body), request)
    assistant = _message(
        conversation_id,
        "assistant",
        str(result.get("response", "")),
        result,
    )
    _MESSAGES[conversation_id].append(assistant)
    _touch_conversation(conversation_id, assistant["content"], result)
    return assistant


@router.post("/conversations/{conversation_id}/messages/stream")
async def stream_message(conversation_id: str, body: Dict[str, Any], request: Request) -> StreamingResponse:
    """Keep the mobile SSE contract while using the canonical BrainV3 stream."""
    _owned_conversation(conversation_id, request)
    content = str(body.get("content") or body.get("message") or "").strip()
    attachments = body.get("attachments") if isinstance(body.get("attachments"), list) else []
    if not content and not attachments:
        raise HTTPException(422, "نص الرسالة أو المرفق مطلوب")
    _MESSAGES[conversation_id].append(_message(conversation_id, "user", content, attachments=attachments))
    item = _CONVERSATIONS[conversation_id]
    if item["title"] == "محادثة جديدة":
        item["title"] = _title_from_message(content, attachments)
    canonical = await chat_stream(_chat_request(content, conversation_id, body), request)
    return StreamingResponse(
        _mobile_events(conversation_id, canonical),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no", "Connection": "keep-alive"},
    )


async def _mobile_events(conversation_id: str, canonical: StreamingResponse):
    """Relay BrainV3 events and persist the completed assistant response."""
    accumulated: List[str] = []
    try:
        async for raw in canonical.body_iterator:
            text = raw.decode("utf-8") if isinstance(raw, bytes) else str(raw)
            for line in text.splitlines():
                if not line.startswith("data: "):
                    continue
                payload_text = line[6:].strip()
                if payload_text == "[DONE]":
                    yield "data: [DONE]\n\n"
                    continue
                try:
                    payload = json.loads(payload_text)
                except json.JSONDecodeError:
                    continue
                if payload.get("event") == "delta":
                    delta = ((payload.get("choices") or [{}])[0].get("delta") or {}).get("content")
                    if delta:
                        accumulated.append(str(delta))
                elif payload.get("event") == "finish":
                    content = "".join(accumulated).strip()
                    if content:
                        assistant = _message(conversation_id, "assistant", content, payload.get("metadata"))
                        _MESSAGES[conversation_id].append(assistant)
                        _touch_conversation(conversation_id, content, payload.get("metadata") or {})
                yield f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"
    except Exception as error:
        yield f"data: {json.dumps({'event': 'error', 'error': str(error)}, ensure_ascii=False)}\n\n"


def _chat_request(content: str, conversation_id: str, body: Dict[str, Any]) -> ChatRequestSchema:
    return ChatRequestSchema(
        message=content,
        session_id=conversation_id,
        language=str(body.get("language") or "ar"),
        use_rag=bool(body.get("use_rag", True)),
        use_agent=bool(body.get("use_agent", False)),
        temperature=body.get("temperature"),
        max_tokens=body.get("max_tokens"),
        model=_groq_model(body.get("model") or body.get("modelId")),
        top_k=int(body.get("top_k", 5)),
        retrieval_mode=str(body.get("retrieval_mode") or "semantic"),
        system_prompt=body.get("system_prompt"),
    )


def _groq_model(raw_model: Any) -> str:
    """Normalize mobile model IDs to the configured Groq provider namespace."""
    raw = str(raw_model or "llama-3.3-70b-versatile").strip()
    if raw.startswith("groq/"):
        return raw
    # Mobile catalogs may expose bare names or an OpenAI-shaped ID. The
    # provider must remain Groq; only the model name is carried forward.
    model_name = raw.split("/", 1)[1] if "/" in raw else raw
    return f"groq/{model_name}"


def _touch_conversation(conversation_id: str, content: str, metadata: Dict[str, Any]) -> None:
    item = _CONVERSATIONS[conversation_id]
    item["lastMessageSnippet"] = content[:160]
    item["updatedAt"] = _now()
    if metadata.get("model"):
        item["aiModelId"] = metadata["model"]
    if metadata.get("provider"):
        item.setdefault("metadata", {})["provider"] = metadata["provider"]


def _title_from_message(content: str, attachments: List[Dict[str, Any]]) -> str:
    clean = " ".join(content.split())
    if clean:
        return clean[:60] + ("…" if len(clean) > 60 else "")
    name = attachments[0].get("name") if attachments and isinstance(attachments[0], dict) else None
    return f"مرفق: {name}" if name else "محادثة مرفقة"


def _message(conversation_id: str, role: str, content: str, metadata: Dict[str, Any] | None = None, attachments: List[Dict[str, Any]] | None = None) -> Dict[str, Any]:
    timestamp = _now()
    return {
        "id": str(uuid.uuid4()),
        "conversationId": conversation_id,
        "role": role,
        "content": content,
        "createdAt": timestamp,
        "updatedAt": timestamp,
        "status": "sent",
        "attachments": attachments or [],
        "toolCalls": [],
        "citations": [],
        "tokenUsage": None,
        "modelMetadata": metadata or {"provider": "hajeen-brain"},
        "isStreaming": False,
        "isEdited": False,
        "isRegenerated": False,
        "reactions": [],
        "parentMessageId": None,
    }


# Mobile feature endpoints: valid empty collections are preferable to client-side 404s
@router.get("/notifications")
async def notifications(request: Request) -> List[Dict[str, Any]]:
    return []


@router.get("/files")
async def list_files(request: Request) -> List[Dict[str, Any]]:
    scope = _scope(request)
    return [item for item in _FILES.values() if item.get("scope") == scope]


@router.post("/files")
async def upload_file(request: Request, file: UploadFile = File(...)) -> Dict[str, Any]:
    content = await file.read()
    if len(content) > 25 * 1024 * 1024:
        raise HTTPException(413, "حجم الملف يتجاوز 25 ميجابايت")
    mime = file.content_type or "application/octet-stream"
    file_id = str(uuid.uuid4())
    item = {
        "id": file_id, "name": file.filename or "file",
        "url": f"data:{mime};base64,{base64.b64encode(content).decode()}",
        "size": len(content), "mimeType": mime, "createdAt": _now(),
        "scope": _scope(request),
    }
    _FILES[file_id] = item
    return {key: value for key, value in item.items() if key != "scope"}


@router.delete("/files/{file_id}")
async def delete_file(file_id: str, request: Request) -> Dict[str, Any]:
    item = _FILES.get(file_id)
    if item is None or item.get("scope") != _scope(request):
        raise HTTPException(404, "الملف غير موجود")
    _FILES.pop(file_id)
    return {"success": True}


@router.get("/agents")
async def agents(request: Request) -> List[Dict[str, Any]]:
    return []


@router.get("/subscriptions")
@router.get("/subscriptions/plans")
async def subscription_plans(request: Request) -> List[Dict[str, Any]]:
    return []


@router.get("/subscriptions/current")
async def current_subscription(request: Request) -> Dict[str, Any]:
    return {
        "id": "none",
        "userId": _scope(request),
        "planType": "custom",
        "billingCycle": "custom",
        "status": "pending",
        "startDate": _now(),
        "endDate": None,
        "price": 0,
        "currency": "USD",
        "features": {},
        "metadata": {"active": False},
    }


@router.post("/subscriptions/{subscription_id}/cancel")
async def cancel_subscription(subscription_id: str, request: Request) -> Dict[str, Any]:
    return {"success": True, "id": subscription_id, "status": "cancelled"}


@router.get("/payments/history")
async def payment_history(request: Request) -> List[Dict[str, Any]]:
    return []


@router.get("/payments/{payment_id}")
async def payment(payment_id: str, request: Request) -> Dict[str, Any]:
    raise HTTPException(404, "عملية الدفع غير موجودة")


@router.patch("/notifications/{notification_id}")
async def mark_notification(notification_id: str, body: Dict[str, Any], request: Request) -> Dict[str, Any]:
    return {"id": notification_id, "read": True}


@router.post("/notifications/read-all")
async def mark_all_notifications_read(request: Request) -> Dict[str, Any]:
    return {"success": True}
