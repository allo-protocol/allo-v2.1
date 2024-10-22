// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./IDrips.sol";

contract DripsExtension {


    IDrips public drips;

    constructor(address dripsAddress) {
        drips = Drips(dripsAddress);
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
            
            //create or validate existince of drips account for each recipient
            // might need to track something here to map IDs

        }

    /// @notice Allocates to recipients.
    /// @param _recipients The addresses of the recipients to allocate to
    /// @param _amounts The amounts to allocate to the recipients
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        external
        payable {

            // create a stream with the recipients

        }

    /// @notice Distributes funds to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external {

        // enable the stream
        


    }
 

}