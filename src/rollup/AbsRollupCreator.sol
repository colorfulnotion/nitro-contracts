// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IBridgeCreator.sol";
import "./IRollupCreator.sol";
import "./RollupProxy.sol";
import "./IRollupAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbsRollupCreator is Ownable, IRollupCreator {
    event RollupCreated(
        address indexed rollupAddress,
        address inboxAddress,
        address outbox,
        address rollupEventInbox,
        address challengeManager,
        address adminProxy,
        address sequencerInbox,
        address bridge,
        address validatorUtils,
        address validatorWalletCreator
    );
    event TemplatesUpdated();

    IBridgeCreator public bridgeCreator;
    IOneStepProofEntry public osp;
    IChallengeManager public challengeManagerTemplate;
    IRollupAdmin public rollupAdminLogic;
    IRollupUser public rollupUserLogic;

    address public validatorUtils;
    address public validatorWalletCreator;

    struct BridgeContracts {
        IBridge bridge;
        ISequencerInbox sequencerInbox;
        IInbox inbox;
        IRollupEventInbox rollupEventInbox;
        IOutbox outbox;
    }

    constructor() Ownable() {}

    function setTemplates(
        IBridgeCreator _bridgeCreator,
        IOneStepProofEntry _osp,
        IChallengeManager _challengeManagerLogic,
        IRollupAdmin _rollupAdminLogic,
        IRollupUser _rollupUserLogic,
        address _validatorUtils,
        address _validatorWalletCreator
    ) external onlyOwner {
        bridgeCreator = _bridgeCreator;
        osp = _osp;
        challengeManagerTemplate = _challengeManagerLogic;
        rollupAdminLogic = _rollupAdminLogic;
        rollupUserLogic = _rollupUserLogic;
        validatorUtils = _validatorUtils;
        validatorWalletCreator = _validatorWalletCreator;
        emit TemplatesUpdated();
    }

    // After this setup:
    // Rollup should be the owner of bridge
    // RollupOwner should be the owner of Rollup's ProxyAdmin
    // RollupOwner should be the owner of Rollup
    // Bridge should have a single inbox and outbox
    function _createRollup(
        Config memory config,
        address _batchPoster,
        address[] calldata _validators,
        address nativeToken
    ) internal returns (address) {
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // Create the rollup proxy to figure out the address and initialize it later
        RollupProxy rollup = new RollupProxy{salt: keccak256(abi.encode(config))}();

        BridgeContracts memory bridgeContracts = _createBridge(
            address(proxyAdmin),
            address(rollup),
            config.sequencerInboxMaxTimeVariation,
            nativeToken
        );

        IChallengeManager challengeManager = IChallengeManager(
            address(
                new TransparentUpgradeableProxy(
                    address(challengeManagerTemplate),
                    address(proxyAdmin),
                    ""
                )
            )
        );
        challengeManager.initialize(
            IChallengeResultReceiver(address(rollup)),
            bridgeContracts.sequencerInbox,
            bridgeContracts.bridge,
            osp
        );

        proxyAdmin.transferOwnership(config.owner);

        // initialize the rollup with this contract as owner to set batch poster and validators
        // it will transfer the ownership back to the actual owner later
        address actualOwner = config.owner;
        config.owner = address(this);
        rollup.initializeProxy(
            config,
            ContractDependencies({
                bridge: bridgeContracts.bridge,
                sequencerInbox: bridgeContracts.sequencerInbox,
                inbox: bridgeContracts.inbox,
                outbox: bridgeContracts.outbox,
                rollupEventInbox: bridgeContracts.rollupEventInbox,
                challengeManager: challengeManager,
                rollupAdminLogic: address(rollupAdminLogic),
                rollupUserLogic: rollupUserLogic,
                validatorUtils: validatorUtils,
                validatorWalletCreator: validatorWalletCreator
            })
        );

        bridgeContracts.sequencerInbox.setIsBatchPoster(_batchPoster, true);

        // Call setValidator on the newly created rollup contract
        bool[] memory _vals = new bool[](_validators.length);
        for (uint256 i = 0; i < _validators.length; i++) {
            _vals[i] = true;
        }
        IRollupAdmin(address(rollup)).setValidator(_validators, _vals);

        IRollupAdmin(address(rollup)).setOwner(actualOwner);

        emit RollupCreated(
            address(rollup),
            address(bridgeContracts.inbox),
            address(bridgeContracts.outbox),
            address(bridgeContracts.rollupEventInbox),
            address(challengeManager),
            address(proxyAdmin),
            address(bridgeContracts.sequencerInbox),
            address(bridgeContracts.bridge),
            address(validatorUtils),
            address(validatorWalletCreator)
        );
        return address(rollup);
    }

    /**
     * Create bridge using appropriate BridgeCreator.
     */
    function _createBridge(
        address proxyAdmin,
        address rollup,
        ISequencerInbox.MaxTimeVariation memory maxTimeVariation,
        address nativeToken
    ) internal virtual returns (BridgeContracts memory);
}
