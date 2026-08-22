# Phase 8 — Canonical Boundaries

| Domain | Canonical boundary | Current status | Evidence |
|---|---|---|---|
| API requests | ChatService | CANONICAL/PARTIAL | API and architecture tests |
| Cognitive orchestration | BrainV3 | CANONICAL | existing contract inventory |
| Model choice | ModelRouter | CANONICAL | routing tests |
| Model admission | ModelRegistry | CANONICAL | registry tests |
| Provider access | ProviderRegistry → BaseLLMProvider | CANONICAL | provider and guardrail tests |
| Memory | Memory facade | PARTIAL | backend ownership not fully proven |
| Retrieval/RAG | Retrieval facade | PARTIAL | tenant-wide persisted proof unavailable |
| Prompt | UnifiedPromptBuilder | PARTIAL | snapshot coverage incomplete |
| Configuration | environment/config modules | PARTIAL | precedence inventory remains |
| Storage | relational/object/vector/cache/artifact owners | PARTIAL | no migration performed |
| Workers | runtime admission contract | TEST_PASS/PARTIAL | local contract tests; distributed worker not proven |

لا يُحذف أي secondary أو legacy implementation بناءً على هذه الوثيقة وحدها.
