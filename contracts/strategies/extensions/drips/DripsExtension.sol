// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./IDrips.sol";
import { StreamConfigImpl } from "./StreamConfigImpl.sol";

contract DripsExtension {


    IDrips public drips;


     mapping (address => uint32) private driverIds;

     uint32 private ownerDriverID;
     address private token;

    constructor(address dripsAddress, address tokenAddress) {
        drips = Drips(dripsAddress);
        token = tokenAddress;
    }


    /// @notice Registers recipients to the strtategy.
    /// @param _recipients The addresses of the recipients to register
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return _recipientIs The recipientIds
    function register(address[] memory _recipients, bytes memory _data, address _sender)
        external
        payable
        returns (address[] memory _recipientIs) {

            // create a driver ID for every recipient
            uint256 recipientLength = _recipients.length;
            for(uint256 i = 0 ; i < recipientLength; i++){
                driverIds[_recipients[i]] = drips.registerDriver(_recipients[i]);
            }
            
            // track the driver id of the fund sender
            ownerDriverID = drips.registerDriver(_sender);
            
         

        }

    /// @notice Allocates to recipients.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        external
        payable {

            // create a stream with the recipients.  this is capped at 100...
            uint8 size = _recipients.length() > 100 ? 100 : _recipients.length();
            StreamReceiver[] receivers = new StreamReceiver[size];

            // start immediatly  but it's empty...?
            StreamConfig config = StreamConfigImpl.create(0, 10 * drips.AMT_PER_SEC_MULTIPLIER, 0, 0);

            uint256 recipientLength = _recipients.length;
            for(uint256 i = 0 ; i < recipientLength; i++){
                receivers[i] = new StreamReceiver(driverIds[_recipients[i]], config);                
            }

            drips.setStreams(
                ownerDriverID,
                token,
                [],
                0,
                receivers,
                0
            );
        }


    // function setStreams(
    //     uint256 accountId,
    //     IERC20 erc20,
    //     StreamReceiver[] memory currReceivers,
    //     int128 balanceDelta,
    //     StreamReceiver[] memory newReceivers,
    //     MaxEndHints maxEndHints
    // ) public onlyDriver(accountId) returns (int128 realBalanceDelta);

        

    /// @notice Distributes funds to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {

        // enable the stream


    



    }
 

}