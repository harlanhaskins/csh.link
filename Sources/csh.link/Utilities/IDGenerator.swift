//
//  IDGenerator.swift
//  CSH-Link
//
//  Created by Harlan Haskins on 9/13/16.
//
//

import Foundation

func log(_ val: Double, _ base: Double) -> Double {
  return log(val)/log(base)
}

enum IDGenerator {
  static let alphabet = Array("23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".characters)
  static let base = alphabet.count
  static let maxLength = 8
  static func encodeID(_ int: Int) -> String {
    var int = abs(int)
    var str = [Character]()
    if int == 0 { return String(alphabet[0]) }
    while int > 0 && str.count < maxLength {
      var rem = 0
      (int, rem) = (int / base, int % base)
      str.append(alphabet[Int(rem)])
    }
    return String(str.reversed())
  }
}
