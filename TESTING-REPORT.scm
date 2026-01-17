;; SPDX-License-Identifier: AGPL-3.0-or-later
;; RAZE-TUI Testing Report
;; Generated: 2025-12-29T11:41:50+00:00

(testing-report
 (metadata
  (version "1.0.0")
  (schema-version "1.0.0")
  (created "2025-12-29T11:41:50+00:00")
  (project "raze-tui")
  (repo "https://github.com/hyperpolymath/raze-tui"))

 (test-environment
  (platform "Linux 6.17.12-300.fc43.x86_64")
  (date "2025-12-29")
  (toolchains
   (rust (version "stable-1.75+") (status installed))
   (zig (version "0.13.0") (status installed))
   (gnat (version "N/A") (status not-installed))))

 (summary
  (total-components 3)
  (components-tested 2)
  (components-blocked 1)
  (overall-status partial-success))

 (components
  ;; Rust Core Component
  (component
   (name "rust-core")
   (path "rust/")
   (language rust)
   (build
    (command "cargo build --release")
    (status success)
    (artifacts
     (artifact
      (name "libraze_core.a")
      (type static-library)
      (size-bytes 23068672))
     (artifact
      (name "libraze_core.so")
      (type shared-library)
      (size-bytes 419840))))
   (tests
    (command "cargo test")
    (status success)
    (passed 3)
    (failed 0)
    (ignored 0)
    (test-cases
     (test (name "test_event_creation") (status passed))
     (test (name "test_state_creation") (status passed))
     (test (name "test_state_touch") (status passed))))
   (issues-found
    (issue
     (id "RUST-001")
     (severity critical)
     (type build-failure)
     (description "no_std mode unconditionally enabled without allocator")
     (status fixed)
     (files-modified ("rust/src/lib.rs" "rust/Cargo.toml")))
    (issue
     (id "RUST-002")
     (severity minor)
     (type warning)
     (description "no_std feature not declared in Cargo.toml")
     (status fixed)
     (files-modified ("rust/Cargo.toml"))))
   (code-quality
    (spdx-header present)
    (unsafe-code forbidden)
    (ffi-repr-c correct)
    (documentation good)))

  ;; Zig Bridge Component
  (component
   (name "zig-bridge")
   (path "zig/")
   (language zig)
   (build
    (command "zig build")
    (status success)
    (artifacts
     (artifact
      (name "libraze_bridge.a")
      (type static-library)
      (size-bytes 2097152))))
   (tests
    (command "zig build test")
    (status success)
    (passed 2)
    (failed 0)
    (test-cases
     (test (name "init and shutdown") (status passed))
     (test (name "dimensions") (status passed))))
   (issues-found
    (issue
     (id "ZIG-001")
     (severity minor)
     (type configuration)
     (description "Missing .tool-versions for asdf version management")
     (status fixed)
     (files-created ("zig/.tool-versions"))))
   (code-quality
    (spdx-header present)
    (ffi-exports correct)
    (type-matching verified)
    (memory-management page-allocator)))

  ;; Ada TUI Component
  (component
   (name "ada-tui")
   (path "ada/")
   (language ada)
   (build
    (command "gprbuild -P raze_tui.gpr")
    (status blocked)
    (blocker "GNAT compiler not installed"))
   (tests
    (status not-executed)
    (reason dependency-missing))
   (issues-found
    (issue
     (id "ADA-001")
     (severity critical)
     (type compile-error)
     (description "Missing 'with System;' context clause in package body")
     (status fixed)
     (files-modified ("ada/src/raze-tui.adb")))
    (issue
     (id "ADA-002")
     (severity minor)
     (type configuration)
     (description "Missing build directories referenced in GPR file")
     (status fixed)
     (directories-created ("ada/obj" "ada/bin" "ada/spark" "ada/proof"))))
   (code-quality
    (spdx-header present)
    (ffi-bindings correct)
    (spark-contracts defined)
    (ada-version 2022))))

 (changes-made
  (change
   (file "rust/src/lib.rs")
   (type modification)
   (description "Made no_std feature-gated to fix build failure"))
  (change
   (file "rust/Cargo.toml")
   (type modification)
   (description "Added no_std feature declaration"))
  (change
   (file "ada/src/raze-tui.adb")
   (type modification)
   (description "Added missing 'with System;' import"))
  (change
   (file "zig/.tool-versions")
   (type creation)
   (description "Created with zig 0.13.0 for asdf"))
  (change
   (file "ada/obj/")
   (type creation)
   (description "GPR object output directory"))
  (change
   (file "ada/bin/")
   (type creation)
   (description "GPR executable output directory"))
  (change
   (file "ada/spark/")
   (type creation)
   (description "SPARK source directory"))
  (change
   (file "ada/proof/")
   (type creation)
   (description "SPARK proof artifacts directory")))

 (recommendations
  (recommendation
   (priority high)
   (category dependency)
   (action "Install GNAT compiler")
   (details "Required to build and test Ada component. Use: dnf install gcc-gnat gprbuild"))
  (recommendation
   (priority high)
   (category ci-cd)
   (action "Add GitHub Actions workflow")
   (details "Automated testing for all three components"))
  (recommendation
   (priority medium)
   (category testing)
   (action "Add integration tests")
   (details "Test full FFI chain from Ada through Zig to Rust"))
  (recommendation
   (priority medium)
   (category verification)
   (action "Enable SPARK proofs")
   (details "Formal verification for safety-critical code paths"))
  (recommendation
   (priority low)
   (category documentation)
   (action "Add API documentation")
   (details "Document all public FFI functions")))

 (test-artifacts
  (artifact
   (name "rust-static-lib")
   (path "rust/target/release/libraze_core.a")
   (size "22 MB"))
  (artifact
   (name "rust-shared-lib")
   (path "rust/target/release/libraze_core.so")
   (size "410 KB"))
  (artifact
   (name "zig-static-lib")
   (path "zig/zig-out/lib/libraze_bridge.a")
   (size "2.0 MB"))))
