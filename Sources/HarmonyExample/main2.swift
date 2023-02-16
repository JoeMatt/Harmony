//
//  main.swift
//  
//
//  Created by Joseph Mattiello on 2/16/23.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#else
#error ("Unsupported OS")
#endif
