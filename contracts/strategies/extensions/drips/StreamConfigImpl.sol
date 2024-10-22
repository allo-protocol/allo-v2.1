pragma solidity ^0.8.24;

import { StreamConfig } from "./IDrips.sol";


library StreamConfigImpl {
    /// @notice Create a new StreamConfig.
    /// @param streamId_ An arbitrary number used to identify a stream.
    /// It's a part of the configuration but the protocol doesn't use it.
    /// @param amtPerSec_ The amount per second being streamed. Must never be zero.
    /// It must have additional `Streams._AMT_PER_SEC_EXTRA_DECIMALS`
    /// decimals and can have fractions.
    /// To achieve that the passed value must be multiplied by `Streams._AMT_PER_SEC_MULTIPLIER`.
    /// @param start_ The timestamp when streaming should start.
    /// If zero, use the timestamp when the stream is configured.
    /// @param duration_ The duration of streaming. If zero, stream until the balance runs out.
    // slither-disable-next-line dead-code
    function create(uint32 streamId_, uint160 amtPerSec_, uint32 start_, uint32 duration_)
        internal
        pure
        returns (StreamConfig)
    {
        // By assignment we get `config` value:
        // `zeros (224 bits) | streamId (32 bits)`
        uint256 config = streamId_;
        // By bit shifting we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | zeros (160 bits)`
        // By bit masking we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        config = (config << 160) | amtPerSec_;
        // By bit shifting we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        config = (config << 32) | start_;
        // By bit shifting we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        config = (config << 32) | duration_;
        return StreamConfig.wrap(config);
    }

    /// @notice Extracts streamId from a `StreamConfig`
    // slither-disable-next-line dead-code
    function streamId(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (224 bits) | streamId (32 bits)`
        // By casting down we get value:
        // `streamId (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 224);
    }

    /// @notice Extracts amtPerSec from a `StreamConfig`
    function amtPerSec(StreamConfig config) internal pure returns (uint160) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        // By casting down we get value:
        // `amtPerSec (160 bits)`
        return uint160(StreamConfig.unwrap(config) >> 64);
    }

    /// @notice Extracts start from a `StreamConfig`
    function start(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        // By casting down we get value:
        // `start (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 32);
    }

    /// @notice Extracts duration from a `StreamConfig`
    function duration(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By casting down we get value:
        // `duration (32 bits)`
        return uint32(StreamConfig.unwrap(config));
    }

    /// @notice Compares two `StreamConfig`s.
    /// First compares `streamId`s, then `amtPerSec`s, then `start`s and finally `duration`s.
    /// @return isLower True if `config` is strictly lower than `otherConfig`.
    function lt(StreamConfig config, StreamConfig otherConfig)
        internal
        pure
        returns (bool isLower)
    {
        // Both configs have value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // Comparing them as integers is equivalent to comparing their fields from left to right.
        return StreamConfig.unwrap(config) < StreamConfig.unwrap(otherConfig);
    }
}
