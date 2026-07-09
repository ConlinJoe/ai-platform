# Laravel Rules

## Architecture

-   Follow Laravel conventions by default.
-   Keep controllers responsible only for HTTP request and response
    handling.
-   Place business logic in services or domain classes.
-   Keep models focused on persistence, relationships, casts, and
    scopes.
-   Prefer dependency injection over facades when practical.

## Database

-   Use Eloquent unless there is a demonstrated performance reason not
    to.
-   Use foreign key constraints.
-   Follow Laravel naming conventions.
-   Create focused migrations.

## Frontend

Preferred stack:

-   Blade
-   Livewire
-   Alpine.js
-   Tailwind CSS

Avoid unnecessary JavaScript frameworks unless the project requires
them.

## Code Quality

-   Follow existing project conventions.
-   Favor readability over cleverness.
-   Build the simplest solution that satisfies the requirements.

## Laravel Boost

When Laravel Boost is available:

- Use Laravel Boost as the primary source for framework guidance.
- Prefer Boost recommendations over generic Laravel knowledge.
- Follow established project patterns unless explicitly directed otherwise.