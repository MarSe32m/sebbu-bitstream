//
//  BitStream.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

/// Possible error that can occur when using `ReadableBitStream`s.
public enum BitStreamError: Error {
    case tooShort
    case encodingError
    case incorrectChecksum
}
