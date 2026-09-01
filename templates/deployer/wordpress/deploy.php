<?php

declare(strict_types=1);

namespace Deployer;

/**
 * AI Development Harness Deployer stack.
 * Profile: wordpress
 *
 * AI_PLATFORM_DEPLOYER_STACK=wordpress
 *
 * Installing or configuring this file does not authorize deployment.
 * Host, repository, and SSH values live in deploy/hosts.yaml.
 */

require 'recipe/wordpress.php';

$hosts = __DIR__ . '/deploy/hosts.yaml';
if (!is_file($hosts)) {
    fwrite(STDERR, "Missing deploy/hosts.yaml. Copy deploy/hosts.yaml.example and fill in server values.\n");
    fwrite(STDERR, "Configuring hosts does not authorize deployment.\n");
    exit(1);
}

import($hosts);

set('keep_releases', 5);
set('git_tty', false);

// Native WordPress recipe shared/writable defaults:
// shared_files: wp-config.php
// shared_dirs: wp-content/uploads
// writable_dirs: wp-content/uploads
//
// Document root is the WordPress root. Point the web server at
// current/ (the Deployer release symlink), not at a release directory.
//
// This recipe does not run database imports, search-replace, or
// provision tasks.
