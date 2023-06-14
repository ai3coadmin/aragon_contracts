pragma solidity 0.8.17;

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup, IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {VetoMultisig, Multisig} from "./Multisig.sol";


contract VetoMultisigPluginSetup is PluginSetup {
    VetoMultisig private immutable multisigBase;
    address public immutable gDAO;

    constructor(address _gDao) {
        multisigBase = new VetoMultisig();
        gDAO = _gDao;
    }



    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes calldata _data
    ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
        // Decode `_data` to extract the params needed for deploying and initializing `Multisig` plugin.
        (address[] memory members, Multisig.MultisigSettings memory multisigSettings) = abi.decode(
            _data,
            (address[], Multisig.MultisigSettings)
        );

        // Prepare and Deploy the plugin proxy.
        plugin = createERC1967Proxy(
            address(multisigBase),
            abi.encodeWithSelector(Multisig.initialize.selector, _dao, members, multisigSettings)
        );

        // Prepare permissions
        PermissionLib.MultiTargetPermission[]
        memory permissions = new PermissionLib.MultiTargetPermission[](6);

        // Set permissions to be granted.
        // Grant the list of prmissions of the plugin to the DAO.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            multisigBase.UPDATE_MULTISIG_SETTINGS_PERMISSION_ID()
        );

        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            multisigBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        // Grant `EXECUTE_PERMISSION` of the DAO to the plugin.
        permissions[2] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            _dao,
            plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );

        permissions[3] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            multisigBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        permissions[4] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            keccak256("VETO_PERMISSION")
        );

        permissions[5] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            keccak256("TAX_PERMISSION")
        );

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUpdate(
        address _dao,
        uint16 _currentBuild,
        SetupPayload calldata _payload
    )
    external
    pure
    override
    returns (bytes memory initData, PreparedSetupData memory preparedSetupData)
    {}

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    ) external view returns (PermissionLib.MultiTargetPermission[] memory permissions) {
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](6);

        // Set permissions to be Revoked.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            multisigBase.UPDATE_MULTISIG_SETTINGS_PERMISSION_ID()
        );

        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            multisigBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        permissions[2] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _dao,
            _payload.plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );

        permissions[3] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            multisigBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        permissions[4] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            keccak256("VETO_PERMISSION")
        );

        permissions[5] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            gDAO,
            PermissionLib.NO_CONDITION,
            keccak256("TAX_PERMISSION")
        );
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return address(multisigBase);
    }
}
