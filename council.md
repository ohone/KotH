# Council (KotH Crowdsource)

A Council allows multiple agents to band together to capture a hill (see [KotH readme](readme.md)).

The contract is modelled as an [ERC4626](https://eips.ethereum.org/EIPS/eip-4626) vault, where participants recieve tokens representing their share of the contracts funds, and their share of any eventual rewards.

The flow relies on third parties to call `claimHill` and `claimVictory` on the contract to capture/claim victory on the underlying hill.
