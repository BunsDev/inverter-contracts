// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

// External Dependencies
import {Initializable} from "@oz-up/proxy/utils/Initializable.sol";
import {
    PausableUpgradeable,
    ContextUpgradeable
} from "@oz-up/security/PausableUpgradeable.sol";

// Internal Dependencies
import {Types} from "src/common/Types.sol";
import {ProposalStorage} from "src/generated/ProposalStorage.sol";

// Internal Libraries
import {LibMetadata} from "src/modules/lib/LibMetadata.sol";

// Internal Interfaces
import {IModule, IProposal} from "src/modules/base/IModule.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";

/**
 * @title Module
 *
 * @dev The base contract for modules.
 *
 *      This contract provides a framework for triggering and receiving proposal
 *      callbacks (via `call` or `delegatecall`) and a modifier to authenticate
 *      callers via the module's proposal.
 *
 *      TODO mp: Update docs. Includes now:
 *          - versioning
 *
 * @author byterocket
 */
abstract contract Module is IModule, ProposalStorage, PausableUpgradeable {
    //--------------------------------------------------------------------------
    // Storage
    //
    // Variables are prefixed with `__Module_`.

    /// @dev The module's proposal instance.
    ///
    /// @custom:invariant Not mutated after initialization.
    IProposal internal __Module_proposal;

    /// @dev The module's metadata.
    ///
    /// @custom:invariant Not mutated after initialization.
    Metadata internal __Module_metadata;

    //--------------------------------------------------------------------------
    // Modifiers
    //
    // Note that the modifiers declared here are available in dowstream
    // contracts too. To not make unnecessary modifiers available, this contract
    // inlines argument validations not needed in downstream contracts.

    /// @notice Modifier to guarantee function is only callable by addresses
    ///         authorized via Proposal.
    /// @dev onlyAuthorized functions SHOULD only be used to trigger callbacks
    ///      from the proposal via the `triggerProposalCallback()` function.
    modifier onlyAuthorized() {
        IAuthorizer authorizer = __Module_proposal.authorizer();
        if (!authorizer.isAuthorized(_msgSender())) {
            revert Module__CallerNotAuthorized();
        }
        _;
    }

    /// @notice Modifier to guarantee function is only callable by the proposal.
    /// @dev onlyProposal functions MUST only access the module's storage, i.e.
    ///      `__Module_` variables.
    /// @dev Note to use function prefix `__Module_`.
    modifier onlyProposal() {
        if (_msgSender() != address(__Module_proposal)) {
            revert Module__OnlyCallableByProposal();
        }
        _;
    }

    /// @notice Modifier to guarantee that the function is not executed in the
    ///         module's context.
    /// @dev As long as wantProposalContext-protected functions only access the
    ///      proposal storage variables (`__Proposal_`) inherited from
    ///      {ProposalStorage}, the module's own state is never mutated.
    /// @dev Note that it's therefore save to not authenticate the caller in
    ///      these functions. A function only accessing the proposal storage
    ///      variables, as recommended, can not alter it's own module's storage.
    /// @dev Note to use function prefix `__Proposal_`.
    modifier wantProposalContext() {
        // If we are in the proposal's context, the following storage access
        // returns the zero address. That is because the module's storage
        // starts after the proposal's storage due to inheriting from
        // {ProposalStorage}.
        // If we are in the module's context, the following storage access can
        // not return the zero address. That is because the `__Module_proposal`
        // variable is set during initialization and never mutated again.
        if (address(__Module_proposal) != address(0)) {
            revert Module__WantProposalContext();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Initialization

    // @todo mp: Check that `_disableInitializers()` is used correctly.
    //           Makes testing setup harder too.
    //constructor() {
    //    _disableInitializers();
    //}

    // @todo mp: Can metaData be calldata? Depends on Factories.

    // @todo mp: param metaData data missing in function doc.
    //           Refactor @dev, function name is `init()`.

    /// @inheritdoc IModule
    function init(
        IProposal proposal_,
        Metadata memory metadata,
        bytes memory /*configdata*/
    ) external virtual initializer {
        __Module_init(proposal_, metadata);
    }

    /// @dev The initialization function MUST be called by the upstream
    ///      contract in their `initialize()` function.
    /// @param proposal_ The module's proposal.
    function __Module_init(IProposal proposal_, Metadata memory metadata)
        internal
        onlyInitializing
    {
        __Pausable_init();

        // Write proposal to storage.
        if (address(proposal_) == address(0)) {
            revert Module__InvalidProposalAddress();
        }
        __Module_proposal = proposal_;

        // Write metadata to storage.
        if (!LibMetadata.isValid(metadata)) {
            revert Module__InvalidMetadata();
        }
        __Module_metadata = metadata;
    }

    //--------------------------------------------------------------------------
    // onlyProposal Functions
    //
    // Proposal callback functions executed via `call`.

    /// @notice Callback function to pause the module.
    /// @dev Only callable by the proposal.
    function __Module_pause() external onlyProposal {
        _pause();
    }

    /// @notice Callback function to unpause the module.
    /// @dev Only callable by the proposal.
    function __Module_unpause() external onlyProposal {
        _unpause();
    }

    //--------------------------------------------------------------------------
    // onlyAuthorized Functions
    //
    // API functions for authenticated users.

    /// @inheritdoc IModule
    function pause() external override (IModule) onlyAuthorized {
        _triggerProposalCallback(
            abi.encodeWithSignature("__Module_pause()"), Types.Operation.Call
        );
    }

    /// @inheritdoc IModule
    function unpause() external override (IModule) onlyAuthorized {
        _triggerProposalCallback(
            abi.encodeWithSignature("__Module_unpause()"), Types.Operation.Call
        );
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    /// @inheritdoc IModule
    function identifier() public view returns (bytes32) {
        return LibMetadata.identifier(__Module_metadata);
    }

    /// @inheritdoc IModule
    function info() external view returns (Metadata memory) {
        return __Module_metadata;
    }

    /// @inheritdoc IModule
    function proposal() external view returns (IProposal) {
        return __Module_proposal;
    }

    //--------------------------------------------------------------------------
    // Internal Functions

    /// @dev Internal function to trigger a callback from the proposal.
    /// @param data The call data for the proposal to call.
    /// @param op Whether the callback should be a `call` or `delegatecall`.
    /// @return Whether the callback succeeded.
    /// @return The return data of the callback.
    function _triggerProposalCallback(bytes memory data, Types.Operation op)
        internal
        returns (bool, bytes memory)
    {
        bool ok;
        bytes memory returnData;
        (ok, returnData) =
            __Module_proposal.executeTxFromModule(address(this), data, op);

        // Note that there is no check whether the proposal callback succeeded.
        // This responsibility is delegated to the caller, i.e. downstream
        // module implementation.
        // However, the {IModule} interface defines a generic error type for
        // failed proposal callbacks that can be used to prevent different
        // custom error types in each implementation.
        return (ok, returnData);
    }
}
