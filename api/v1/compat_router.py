"""Flutter compatibility routes backed by the canonical Hajeen Brain runtime."""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from api.v1.ai.router import ChatRequestSchema, chat, chat_stream

router = APIRouter(tags=["Flutter compatibility"])
_CONVERSATIONS: Dict[str, Dict[str, Any]] = {}
_MESSAGES: Dict[str, List[Dict[str, Any]]] = {}


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
async def list_conversations() -> List[Dict[str, Any]]:
    return list(_CONVERSATIONS.values())


@router.post("/conversations")
async def create_conversation(body: Dict[str, Any]) -> Dict[str, Any]:
    conversation_id = str(uuid.uuid4())
    item = _conversation(conversation_id, str(body.get("title") or "محادثة جديدة"))
    _CONVERSATIONS[conversation_id] = item
    _MESSAGES[conversation_id] = []
    return item


@router.patch("/conversations/{conversation_id}")
async def update_conversation(conversation_id: str, body: Dict[str, Any]) -> Dict[str, Any]:
    item = _CONVERSATIONS.get(conversation_id)
    if item is None:
        raise HTTPException(404, "المحادثة غير موجودة")
    if body.get("title"):
        item["title"] = str(body["title"])
    item["updatedAt"] = _now()
    return item


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str) -> Dict[str, Any]:
    if conversation_id not in _CONVERSATIONS:
        raise HTTPException(404, "المحادثة غير موجودة")
    _CONVERSATIONS.pop(conversation_id, None)
    _MESSAGES.pop(conversation_id, None)
    return {"success": True}


@router.get("/conversations/{conversation_id}/messages")
async def list_messages(conversation_id: str) -> List[Dict[str, Any]]:
    if conversation_id not in _CONVERSATIONS:
        raise HTTPException(404, "المحادثة غير موجودة")
    return _MESSAGES.get(conversation_id, [])


@router.post("/conversations/{conversation_id}/messages")
async def create_message(conversation_id: str, body: Dict[str, Any], request: Request) -> Dict[str, Any]:
    if conversation_id not in _CONVERSATIONS:
        raise HTTPException(404, "المحادثة غير موجودة")
    content = str(body.get("content") or body.get("message") or "").strip()
    if not content:
        raise HTTPException(422, "نص الرسالة مطلوب")
    _MESSAGES[conversation_id].append(_message(conversation_id, "user", content))
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
    if conversation_id not in _CONVERSATIONS:
        raise HTTPException(404, "المحادثة غير موجودة")
    content = str(body.get("content") or body.get("message") or "").strip()
    if not content:
        raise HTTPException(422, "نص الرسالة مطلوب")
    _MESSAGES[conversation_id].append(_message(conversation_id, "user", content))
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
        model=body.get("model"),
        top_k=int(body.get("top_k", 5)),
        retrieval_mode=str(body.get("retrieval_mode") or "semantic"),
        system_prompt=body.get("system_prompt"),
    )


def _touch_conversation(conversation_id: str, content: str, metadata: Dict[str, Any]) -> None:
    item = _CONVERSATIONS[conversation_id]
    item["lastMessageSnippet"] = content[:160]
    item["updatedAt"] = _now()
    if metadata.get("model"):
        item["aiModelId"] = metadata["model"]
    if metadata.get("provider"):
        item.setdefault("metadata", {})["provider"] = metadata["provider"]


def _message(conversation_id: str, role: str, content: str, metadata: Dict[str, Any] | None = None) -> Dict[str, Any]:
    timestamp = _now()
    return {
        "id": str(uuid.uuid4()),
        "conversationId": conversation_id,
        "role": role,
        "content": content,
        "createdAt": timestamp,
        "updatedAt": timestamp,
        "status": "sent",
        "attachments": [],
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
