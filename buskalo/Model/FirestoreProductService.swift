//
//  FirestoreProductService.swift
//  buskalo
//
//  Created by crizcode on 2/19/23.
//  Copyright © 2023 crizcode. All rights reserved.
//
import Foundation
import FirebaseFirestore
import Firebase

class FirebaseProductService: ProductService {
    private let db = Firestore.firestore()

    func createProduct(_ product: Product) async throws {
        try await db.collection("products").addDocument(data: product.toDictionary())
    }
}
