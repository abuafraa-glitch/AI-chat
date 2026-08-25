from __future__ import annotations

import logging
from typing import Dict, Type

from shared.schemas.channel import ChannelConfig
from data_engine.channels.base import BaseChannel, FetchResult
from data_engine.channels.predefined.demo_channel import DemoChannel
from shared.exceptions import ChannelException, ValidationException

logger = logging.getLogger(__name__)


class RSSChannel(BaseChannel):
    async def fetch(self, last_fetched_id: str | None = None) -> FetchResult:
        from data_engine.ingestion.crawlers.rss_parser import parse_rss_feed
        try:
            articles = await parse_rss_feed(str(self.config.source.url), source_id=self.config.id, default_language=self.config.source.params.get("language", "en"))
            return FetchResult(articles=articles, has_more=False)
        except Exception as exc:
            logger.error("RSSChannel.fetch failed: %s", exc)
            return FetchResult(articles=[], has_more=False)

    async def validate_source(self) -> bool:
        from data_engine.ingestion.crawlers.rss_parser import validate_rss_feed
        return await validate_rss_feed(str(self.config.source.url))


class APIChannel(BaseChannel):
    async def fetch(self, last_fetched_id: str | None = None) -> FetchResult:
        return FetchResult(articles=[], has_more=False)

    async def validate_source(self) -> bool:
        return True


class PlaceholderChannel(BaseChannel):
    async def fetch(self, last_fetched_id: str | None = None) -> FetchResult:
        return FetchResult(articles=[], has_more=False)

    async def validate_source(self) -> bool:
        return True


_CHANNEL_TYPE_MAP: Dict[str, Type[BaseChannel]] = {
    "rss": RSSChannel,
    "api": APIChannel,
    "demo": DemoChannel,
    "placeholder": PlaceholderChannel,
}


BUILTIN_CHANNEL_TYPES = frozenset(_CHANNEL_TYPE_MAP)


class ChannelBuilder:
    _channel_types: Dict[str, Type[BaseChannel]] = _CHANNEL_TYPE_MAP

    @classmethod
    def register_channel_type(cls, type_name: str, channel_class: Type[BaseChannel]) -> None:
        if not issubclass(channel_class, BaseChannel):
            raise ChannelException("Registered channel class must inherit from BaseChannel.")
        cls._channel_types[type_name.lower()] = channel_class

    @classmethod
    async def create(cls, channel_type: str, config: ChannelConfig) -> BaseChannel:
        key = channel_type.lower()
        channel_class = cls._channel_types.get(key)
        if channel_class is None:
            raise ChannelException(f"Unknown channel type: '{channel_type}'. Available types: {list(cls._channel_types.keys())}")
        await cls.validate_config(config)
        return channel_class(config=config)

    @classmethod
    async def create_from_config(cls, config: ChannelConfig) -> BaseChannel:
        if not isinstance(config, ChannelConfig):
            raise ValidationException("Input must be a ChannelConfig object.")
        return await cls.create(config.source.type, config)

    @classmethod
    async def validate_config(cls, config: ChannelConfig) -> bool:
        if not isinstance(config, ChannelConfig):
            raise ValidationException("Input must be a ChannelConfig object.")
        key = config.source.type.lower()
        if key not in cls._channel_types:
            raise ValidationException(f"Unsupported channel type in config: {config.source.type}")
        channel_class = cls._channel_types[key]
        # Built-in channel construction is configuration-only; network/source
        # validation belongs to the fetch/health path. Custom registrations may
        # provide an explicit validation contract used during construction.
        if key not in BUILTIN_CHANNEL_TYPES:
            try:
                valid = await channel_class(config=config).validate_source()
            except ValidationException as exc:
                raise ValidationException(f"Channel-specific validation failed for type {key}: {exc}") from exc
            except Exception as exc:
                raise ValidationException(f"Channel-specific validation failed for type {key}: {exc}") from exc
            if valid is False:
                raise ValidationException(f"Channel-specific validation failed for type {key}")
        return True
