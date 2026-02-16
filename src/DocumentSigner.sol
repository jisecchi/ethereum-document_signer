// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DocumentRegistry
 * @dev Smart contract for storing and verifying document hashes with signatures
 */
contract DocumentRegistry {
    // Struct to store document information
    struct Document {
        bytes32 hash;
        uint256 timestamp;
        address signer;  // Used to check existence: signer != address(0)
        bytes signature;
    }

    // Mapping from document hash to Document struct
    mapping(bytes32 => Document) public documents;
    
    // Array to store all document hashes for enumeration
    bytes32[] public documentHashes;
    
    // No need for separate hashExists mapping - we check documents[_hash].signer != address(0)

    // Events
    event DocumentStored(
        bytes32 indexed hash,
        address indexed signer,
        uint256 timestamp,
        bytes signature
    );
    
    event DocumentVerified(
        bytes32 indexed hash,
        address indexed signer,
        bool isValid
    );

    // Modifiers
    modifier documentNotExists(bytes32 _hash) {
        require(documents[_hash].signer == address(0), "Document already exists");
        _;
    }

    modifier documentExists(bytes32 _hash) {
        require(documents[_hash].signer != address(0), "Document does not exist");
        _;
    }

    /**
     * @dev Store a document hash with signature
     * @param _hash The hash of the document
     * @param _timestamp The timestamp when the document was created
     * @param _signature The signature of the document hash
     * @param _signer The address of the signer
     */
    function storeDocumentHash(
        bytes32 _hash,
        uint256 _timestamp,
        bytes memory _signature,
        address _signer
    ) external documentNotExists(_hash) {
        // Simple validation - just check signature is not empty
        require(_signature.length > 0, "Invalid signature");
        
        documents[_hash] = Document({
            hash: _hash,
            timestamp: _timestamp,
            signer: _signer,
            signature: _signature
        });
        
        documentHashes.push(_hash);
        
        emit DocumentStored(_hash, _signer, _timestamp, _signature);
    }

    /**
     * @dev Verify a document signature (simplified)
     * @param _hash The hash of the document
     * @param _signer The address of the signer
     * @param _signature The signature to verify
     * @return isValid True if the signature is valid
     */
    function verifyDocument(
        bytes32 _hash,
        address _signer,
        bytes memory _signature
    ) external returns (bool isValid) {
        // Simplified verification - check if document exists and signer matches
        Document memory doc = documents[_hash];
        
        if (doc.signer == address(0)) {
            isValid = false;
        } else {
            // Check if the signer matches and signature is not empty
            isValid = (doc.signer == _signer && doc.signature.length > 0 && _signature.length > 0);
        }
        
        emit DocumentVerified(_hash, _signer, isValid);
        return isValid;
    }

    /**
     * @dev Get complete document information
     * @param _hash The hash of the document
     * @return document The complete document struct
     */
    function getDocumentInfo(bytes32 _hash) 
        external 
        view 
        documentExists(_hash) 
        returns (Document memory document) 
    {
        return documents[_hash];
    }

    /**
     * @dev Get document signature
     * @param _hash The hash of the document
     * @return signature The signature of the document
     */
    function getDocumentSignature(bytes32 _hash) 
        external 
        view 
        documentExists(_hash) 
        returns (bytes memory signature) 
    {
        return documents[_hash].signature;
    }

    /**
     * @dev Check if a document exists
     * @param _hash The hash of the document
     * @return exists True if the document exists
     */
    function isDocumentStored(bytes32 _hash) external view returns (bool exists) {
        return documents[_hash].signer != address(0);
    }

    /**
     * @dev Get total number of documents
     * @return count The total number of stored documents
     */
    function getDocumentCount() external view returns (uint256 count) {
        return documentHashes.length;
    }

    /**
     * @dev Get document hash by index
     * @param _index The index of the document
     * @return hash The hash of the document at the given index
     */
    function getDocumentHashByIndex(uint256 _index) 
        external 
        view 
        returns (bytes32 hash) 
    {
        require(_index < documentHashes.length, "Index out of bounds");
        return documentHashes[_index];
    }
}