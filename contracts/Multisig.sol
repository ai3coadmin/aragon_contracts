pragma solidity 0.8.17;

import {Multisig} from "@aragon/osx/plugins/governance/multisig/Multisig.sol";
import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";

import {Addresslist} from "@aragon/osx/plugins/utils/Addresslist.sol";
import {IMultisig} from "@aragon/osx/plugins/governance/multisig/IMultisig.sol";
import {ITaxManager} from "./TaxManager.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";

contract VetoMultisig is Multisig {

    /// @notice An tax manager which would be setted by Governance Dao
    ITaxManager public taxManager;

    /// @notice Permissions
    bytes32 public constant VETO_PERMISSION_ID = keccak256("VETO_PERMISSION");
    bytes32 public constant TAX_PERMISSION_ID = keccak256("TAX_PERMISSION");

    bytes4 public constant MULTISIG_INTERFACE_ID_CHECK =
    this.initializeBuild.selector ^
    this.updateMultisigSettings.selector ^
    this.createProposal.selector ^
    this.getProposal.selector;

    event TaxChanged(
        uint256 newTax,
        uint256 oldTax
    );

    error ZeroAmount();

    event CancelVote(uint256 _proposalId);

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );



    /// @notice Initializes Release 1, Build 2.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _multisigSettings The multisig settings.
    function initializeBuild(
        IDAO _dao,
        address[] calldata _members,
        MultisigSettings calldata _multisigSettings,
        address _taxManager
    ) external initializer {
        __PluginUUPSUpgradeable_init(_dao);

        if (_members.length > type(uint16).max) {
            revert AddresslistLengthOutOfBounds({limit: type(uint16).max, actual: _members.length});
        }

        _addAddresses(_members);
        emit MembersAdded({members: _members});

        _updateMultisigSettings(_multisigSettings);
        taxManager = ITaxManager(_taxManager);
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(Multisig) returns (bool) {
        return
        _interfaceId == MULTISIG_INTERFACE_ID_CHECK ||
        _interfaceId == MULTISIG_INTERFACE_ID ||
        _interfaceId == type(IMultisig).interfaceId ||
        _interfaceId == type(Addresslist).interfaceId ||
        _interfaceId == type(IMembership).interfaceId ||
        super.supportsInterface(_interfaceId);
    }

    function setTaxManager(address _tax) external auth(TAX_PERMISSION_ID)  returns (bool)  {
        taxManager = ITaxManager(_tax);
        return true;
    }

    function cancelVote(uint256 _proposalId) external auth(VETO_PERMISSION_ID) returns (uint256) {
        // create a modifier here checking whether the proposal is still active, otherwise cancelling would make no point and transaction should be reverted
        Proposal storage proposal = proposals[_proposalId];
        proposal = proposals[_proposalId]; // `proposals` would be your mapping of proposals

        require(
            proposal.parameters.endDate >= uint64(block.timestamp),
            "Impossible to cancel already voted!"
        );

        emit CancelVote(_proposalId);
        proposal.parameters.endDate = uint64(block.timestamp);

        return _proposalId;
    }


    function deposit(
        uint256 _amount,
        string calldata _reference
    ) external payable {
        uint256 taxAmount = 0;
        uint256 tax = taxManager.getTaxRate();
        if (_amount == 0) revert ZeroAmount();
        if (tax != 0) {
            taxAmount = _amount * tax / 100;
        }
        // TODO: Let us know what to do here
//        emit Deposited(msg.sender, address(votingToken), _amount, _reference);
    }
}
