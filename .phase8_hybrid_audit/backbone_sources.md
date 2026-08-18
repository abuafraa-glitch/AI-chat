# Backbone source notes

## Qwen3
- Official Qwen blog: https://qwenlm.github.io/blog/qwen3/
- Official Qwen3 technical report: https://arxiv.org/abs/2505.09388
- NVIDIA NeMo Qwen3 MoE coverage: https://docs.nvidia.com/nemo/automodel/model-coverage/large-language-models/qwen/qwen3-moe
- Search result confirms Qwen3 includes dense and MoE models. The official Qwen blog reports open-weight MoE releases including Qwen3-235B-A22B under Apache 2.0; exact candidate claims must be checked against the candidate's official model card before adoption.

## Llama
- Meta Llama 3.1 announcement: https://ai.meta.com/blog/meta-llama-3-1/
- Meta Llama model card repository: https://github.com/meta-llama/llama/blob/main/MODEL_CARD.md
- Search results indicate Llama licensing is a custom community/commercial license rather than Apache 2.0; final decision must reference the exact candidate model card.

## Mistral
- Official Mistral model overview: https://docs.mistral.ai/models
- Official Mistral licensing guidance: https://help.mistral.ai/en/articles/347393-under-which-license-are-mistral-s-open-models-available
- Search results indicate many Mistral open models use Apache 2.0, but each candidate's model card must be checked individually.

## Caution
Search snippets are discovery only. The blueprint must not claim exact parameter counts, active parameters, context lengths, expert counts, or hardware requirements without verifying the exact official candidate model cards and technical documentation.

## Candidate-specific official note
The official Qwen3 announcement states that Qwen3-30B-A3B is a smaller MoE with 30 billion total parameters and 3 billion activated parameters, and identifies an Apache 2.0 license. Official page: https://qwenlm.github.io/blog/qwen3/ . The exact production candidate still requires pinning an exact model-card revision and verifying tokenizer/config/checksum before any later build.
