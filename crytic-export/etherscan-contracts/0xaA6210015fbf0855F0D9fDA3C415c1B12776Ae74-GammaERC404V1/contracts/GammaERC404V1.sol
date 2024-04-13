//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OERC404} from "./OERC404.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract GammaERC404V1 is OERC404 
{
    string public baseURI;

    constructor(uint256 _initialSupplyERC20, address _lzEndpoint, address _delegate)
        OERC404("TESTGAMMAERC404", "TGEC", 50, _lzEndpoint, _delegate)
        Ownable(_delegate) 
    {
        // Do not mint the ERC721s to the initial owner, as it's a waste of gas.
        _setWhitelist(_delegate, true);
        _mintERC20(_delegate, _initialSupplyERC20);
    }

    function tokenURI(uint256 id) public view override returns (string memory) 
    {
        string memory image = "https://indigo-wasteful-bee-731.mypinata.cloud/ipfs/QmQNxdJsRfhAPkhrj2s5Xt1vEgfxJyfpaycdhPbefAeiww";

        string memory jsonPreImage = string.concat(
            string.concat(
                string.concat('{"name": "OTG404 #', Strings.toString(id)),
                '","description":"The frontier of permissionless assets.","external_url":"https://twitter.com/testX","image":"'
            ),
            string.concat(baseURI, image)
        );
        string memory jsonPostImage = string.concat('"}');

        return string.concat("data:application/json;utf8,", string.concat(jsonPreImage, jsonPostImage));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setWhitelist(address account_, bool value_) external onlyOwner {
        _setWhitelist(account_, value_);
    }
}