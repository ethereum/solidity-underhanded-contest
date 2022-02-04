// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2; // Required for Diamond Standard

// Latest published version now is 1.3.5
import "https://github.com/mudgen/diamond-1/blob/1.3.5/contracts/Diamond.sol";
import "https://github.com/mudgen/diamond-1/blob/1.3.5/contracts/facets/DiamondCutFacet.sol";

library ManagerDataA {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("org.soliditylang.underhanded.submission224.storage");

    struct DiamondStorage {
        uint256 proposedUpgradeTime;
        bool hasAnybodyVetoed;
        
        // diamondCut() call parameters:
        IDiamondCut.FacetCut[] readyDiamondCut;
        address readyInit;
        bytes readyCalldata;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract ManagerFacet1 is DiamondCutFacet {
    function proposeUpgrade(IDiamondCut.FacetCut[] calldata proposedDiamondCut, address proposedInit, bytes calldata ProposedCalldata) public {
        assert(msg.sender == LibDiamond.contractOwner());
        ManagerDataA.diamondStorage().proposedUpgradeTime = block.timestamp;
        ManagerDataA.diamondStorage().hasAnybodyVetoed = false;
        delete ManagerDataA.diamondStorage().readyDiamondCut;
        
        for (uint256 facetIndex; facetIndex < proposedDiamondCut.length; facetIndex++) {
            ManagerDataA.diamondStorage().readyDiamondCut.push(
                FacetCut(
                    proposedDiamondCut[facetIndex].facetAddress,
                    proposedDiamondCut[facetIndex].action,
                    proposedDiamondCut[facetIndex].functionSelectors
                )
            );
        }
        
        ManagerDataA.diamondStorage().readyInit = proposedInit;
        ManagerDataA.diamondStorage().readyCalldata = ProposedCalldata;
    }

    // Anybody can veto the upgrade, that will stop the owner from upgrading
    function vetoUpgrade() public {
        ManagerDataA.diamondStorage().hasAnybodyVetoed = true;
    }

    // Give owner full permission to upgrade, re-implemented in v2
    function isUpgradeConsented() public returns(bool) {
        return true;
    }
    
    function performUpgrade() public {
        assert(isUpgradeConsented());
        assert(block.timestamp > ManagerDataA.diamondStorage().proposedUpgradeTime + 60*60*24*30);

        // These lines copy-pasted from
        // https://github.com/mudgen/diamond-1/blob/1.3.5/contracts/facets/DiamondCutFacet.sol#L26-L36
        // with variables renamed to ready* as above
        uint256 selectorCount = LibDiamond.diamondStorage().selectors.length;
        for (uint256 facetIndex; facetIndex < ManagerDataA.diamondStorage().readyDiamondCut.length; facetIndex++) {
            selectorCount = LibDiamond.addReplaceRemoveFacetSelectors(
                selectorCount,
                ManagerDataA.diamondStorage().readyDiamondCut[facetIndex].facetAddress,
                ManagerDataA.diamondStorage().readyDiamondCut[facetIndex].action,
                ManagerDataA.diamondStorage().readyDiamondCut[facetIndex].functionSelectors
            );
        }
        emit DiamondCut(ManagerDataA.diamondStorage().readyDiamondCut, ManagerDataA.diamondStorage().readyInit, ManagerDataA.diamondStorage().readyCalldata);
        LibDiamond.initializeDiamondCut(ManagerDataA.diamondStorage().readyInit, ManagerDataA.diamondStorage().readyCalldata);
        // end copy-paste

        delete ManagerDataA.diamondStorage().proposedUpgradeTime;
        delete ManagerDataA.diamondStorage().hasAnybodyVetoed;
        delete ManagerDataA.diamondStorage().readyDiamondCut;
        delete ManagerDataA.diamondStorage().readyInit;
        delete ManagerDataA.diamondStorage().readyCalldata;
    }
    
    function proposeUpgradeSEL() public pure returns(bytes4) {return this.proposeUpgrade.selector;}
    function vetoUpgradeSEL() public pure returns(bytes4) {return this.vetoUpgrade.selector;}
    function isUpgradeConsentedSEL() public pure returns(bytes4) {return this.isUpgradeConsented.selector;}
    function performUpgradeSEL() public pure returns(bytes4) {return this.performUpgrade.selector;}
}

/* ******************************************************************************************** */

contract ScholarshipFacet1 {
    // This is the well-known address of Mary Princeton, a deserving scholar
    address payable constant MARY_PRINCETON = 0x829bD824b016326a401D083B33D093a93333a830;
    
    // Only the scholar may take funds
    function takeScholarship() public {
        assert(msg.sender == MARY_PRINCETON);
        MARY_PRINCETON.transfer(address(this).balance);
    }
    
    function takeScholarshipSEL() public pure returns(bytes4) {return this.takeScholarship.selector;}
}

/* ******************************************************************************************** */

contract ManagerFacet2 is DiamondCutFacet{
    // Give owner full permission to upgrade, re-implemented in v2
    function isUpgradeConsented() public returns(bool) {
        return ManagerDataA.diamondStorage().hasAnybodyVetoed == false;
    }
    
    function isUpgradeConsentedSEL() public pure returns(bytes4) {return this.isUpgradeConsented.selector;}
}
