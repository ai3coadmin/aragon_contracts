pragma solidity 0.8.17;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface ITaxManager {
    function getFeeReceiver() external view returns (address);
    function setFeeReceiver(address _feeReceiver) external returns (bool);
    function getTaxRate() external view returns (uint256);
    function setTaxRate(uint256 _tax) external returns (bool);
}

contract TaxManager is Ownable, ITaxManager {
    uint256 public tax = 0;
    address public feeReceiver;
    constructor() {
        feeReceiver = _msgSender();
    }

    function getFeeReceiver() external view returns (address)  {
        return feeReceiver;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner returns (bool)  {
        feeReceiver = _feeReceiver;
        return true;
    }

    function getTaxRate() external view returns (uint256)  {
        return tax;
    }

    function setTaxRate(uint256 _tax) external onlyOwner returns (bool)  {
        tax = _tax;
        return true;
    }
}
