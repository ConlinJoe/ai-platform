<?php

declare(strict_types=1);

namespace Deployer;

/**
 * AI Development Harness Deployer stack.
 * Profile: laravel
 *
 * AI_PLATFORM_DEPLOYER_STACK=laravel
 *
 * Installing or configuring this file does not authorize deployment.
 * Host, repository, and SSH values live in deploy/hosts.yaml.
 */

require 'recipe/laravel.php';

$hosts = __DIR__ . '/deploy/hosts.yaml';
if (!is_file($hosts)) {
    fwrite(STDERR, "Missing deploy/hosts.yaml. Copy deploy/hosts.yaml.example and fill in server values.\n");
    fwrite(STDERR, "Configuring hosts does not authorize deployment.\n");
    exit(1);
}

import($hosts);

set('keep_releases', 5);
set('git_tty', false);

// Native Laravel recipe shared/writable defaults:
// shared_files: .env
// shared_dirs: storage
// writable_dirs: bootstrap/cache, storage
// public_path: public
//
// The native Laravel deploy flow includes artisan:migrate. That still
// requires explicit deployment authorization. This recipe does not hook
// artisan:migrate:fresh, db:wipe, db:seed, or provision tasks.
//
// Frontend builds (Vite/npm) are not in the default deploy flow. See
// docs/contracts/features/deployment.md in this project.

desc('Build frontend assets (not in the default deploy flow)');
task('assets:build', function () {
    run('cd {{release_path}} && npm ci && npm run build');
});
