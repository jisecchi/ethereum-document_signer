// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DocumentRegistry} from "../src/DocumentSigner.sol";

contract DocumentRegistryTest is Test {
    DocumentRegistry public registry;

    address public signer1 = address(0x1);
    address public signer2 = address(0x2);

    bytes32 public docHash1 = keccak256("document1");
    bytes32 public docHash2 = keccak256("document2");

    bytes public signature1 = hex"aabbccdd";
    bytes public signature2 = hex"eeff0011";

    uint256 public timestamp1 = 1700000000;
    uint256 public timestamp2 = 1700001000;

    function setUp() public {
        registry = new DocumentRegistry();
    }

    // ==========================================
    // Test 1: Almacenar documento correctamente
    // ==========================================
    function test_StoreDocument() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);

        DocumentRegistry.Document memory doc = registry.getDocumentInfo(docHash1);
        assertEq(doc.hash, docHash1, "Hash should match");
        assertEq(doc.timestamp, timestamp1, "Timestamp should match");
        assertEq(doc.signer, signer1, "Signer should match");
        assertEq(doc.signature, signature1, "Signature should match");
    }

    // ==========================================
    // Test 2: Evento DocumentStored se emite
    // ==========================================
    function test_StoreDocumentEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit DocumentRegistry.DocumentStored(docHash1, signer1, timestamp1, signature1);

        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);
    }

    // ==========================================
    // Test 3: Rechazar documentos duplicados
    // ==========================================
    function test_RejectDuplicateDocument() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);

        vm.expectRevert("Document already exists");
        registry.storeDocumentHash(docHash1, timestamp2, signature2, signer2);
    }

    // ==========================================
    // Test 4: Rechazar firma vacía
    // ==========================================
    function test_RejectEmptySignature() public {
        bytes memory emptySignature = "";

        vm.expectRevert("Invalid signature");
        registry.storeDocumentHash(docHash1, timestamp1, emptySignature, signer1);
    }

    // ==========================================
    // Test 5: Verificar documento válido
    // ==========================================
    function test_VerifyDocumentValid() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);

        bool isValid = registry.verifyDocument(docHash1, signer1, signature1);
        assertTrue(isValid, "Document should be valid");
    }

    // ==========================================
    // Test 6: Verificar documento con firmante incorrecto
    // ==========================================
    function test_VerifyDocumentInvalidSigner() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);

        bool isValid = registry.verifyDocument(docHash1, signer2, signature1);
        assertFalse(isValid, "Document should be invalid with wrong signer");
    }

    // ==========================================
    // Test 7: Verificar documento inexistente
    // ==========================================
    function test_VerifyDocumentNonExistent() public {
        bool isValid = registry.verifyDocument(docHash1, signer1, signature1);
        assertFalse(isValid, "Non-existent document should be invalid");
    }

    // ==========================================
    // Test 8: Obtener información correcta del documento
    // ==========================================
    function test_GetDocumentInfo() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);
        registry.storeDocumentHash(docHash2, timestamp2, signature2, signer2);

        DocumentRegistry.Document memory doc1 = registry.getDocumentInfo(docHash1);
        assertEq(doc1.hash, docHash1);
        assertEq(doc1.signer, signer1);

        DocumentRegistry.Document memory doc2 = registry.getDocumentInfo(docHash2);
        assertEq(doc2.hash, docHash2);
        assertEq(doc2.signer, signer2);
    }

    // ==========================================
    // Test 9: Rechazar consulta de documento inexistente
    // ==========================================
    function test_GetDocumentInfoNonExistent() public {
        vm.expectRevert("Document does not exist");
        registry.getDocumentInfo(docHash1);
    }

    // ==========================================
    // Test 10: Contar documentos correctamente
    // ==========================================
    function test_GetDocumentCount() public {
        assertEq(registry.getDocumentCount(), 0, "Initial count should be 0");

        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);
        assertEq(registry.getDocumentCount(), 1, "Count should be 1 after storing one document");

        registry.storeDocumentHash(docHash2, timestamp2, signature2, signer2);
        assertEq(registry.getDocumentCount(), 2, "Count should be 2 after storing two documents");
    }

    // ==========================================
    // Test 11: Obtener hash por índice e iterar
    // ==========================================
    function test_GetDocumentHashByIndex() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);
        registry.storeDocumentHash(docHash2, timestamp2, signature2, signer2);

        bytes32 hash0 = registry.getDocumentHashByIndex(0);
        bytes32 hash1 = registry.getDocumentHashByIndex(1);

        assertEq(hash0, docHash1, "First hash should match docHash1");
        assertEq(hash1, docHash2, "Second hash should match docHash2");
    }

    // ==========================================
    // Tests adicionales de robustez
    // ==========================================

    function test_GetDocumentHashByIndexOutOfBounds() public {
        vm.expectRevert("Index out of bounds");
        registry.getDocumentHashByIndex(0);
    }

    function test_IsDocumentStored() public {
        assertFalse(registry.isDocumentStored(docHash1), "Should not exist initially");

        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);
        assertTrue(registry.isDocumentStored(docHash1), "Should exist after storing");

        assertFalse(registry.isDocumentStored(docHash2), "Other hash should not exist");
    }

    function test_GetDocumentSignature() public {
        registry.storeDocumentHash(docHash1, timestamp1, signature1, signer1);

        bytes memory sig = registry.getDocumentSignature(docHash1);
        assertEq(sig, signature1, "Signature should match");
    }

    function test_GetDocumentSignatureNonExistent() public {
        vm.expectRevert("Document does not exist");
        registry.getDocumentSignature(docHash1);
    }
}
