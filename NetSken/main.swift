//
//  main.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

// Create the application instance
let app = NSApplication.shared

// Create and set the app delegate
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)