//
//  ProductModel.swift
//  buskalo
//
//  Created by crizcode on 2/11/23.
//  Copyright © 2023 crizcode. All rights reserved.
//
import UIKit
import Foundation

class Product {
    var nomprod: String
    var descprod: String
    var precprod: Double
    var urlprod: String
    var image: UIImage?
    var documentID: String?
    
   init(nomprod: String, descprod: String, precprod: Double, urlprod: String) {
            self.nomprod = nomprod
            self.descprod = descprod
            self.precprod = precprod
            self.urlprod = urlprod
        }
        
        func getNomProd() -> String {
            return nomprod
        }
        
        func setNomProd(nuevoNomProd: String) {
            nomprod = nuevoNomProd
        }
        
        func getDescProd() -> String {
            return descprod
        }
        
        func setDescProd(nuevoDescProd: String) {
            descprod = nuevoDescProd
        }
        
        func getPrecProd() -> Double {
            return precprod
        }
        
        func setPrecProd(nuevoPrecProd: Double) {
            precprod = nuevoPrecProd
        }
        
        func getURLProd() -> String {
            return urlprod
        }
        
        func setURLProd(nuevaURLProd: String) {
            urlprod = nuevaURLProd
        }
    

    
}
