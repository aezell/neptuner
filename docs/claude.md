# Claude Commands

This Phoenix SaaS template includes custom Claude commands to help with development. These commands are available through the `/.claude/commands/` directory and can be invoked using the `/command-name` syntax.

## Available Commands

### `/code-review`
Reviews Phoenix code changes against template standards and best practices.

**Usage:** `/code-review`

**What it does:**
- Analyzes git diff from HEAD to review current changes
- Checks adherence to Phoenix conventions and patterns
- Validates security best practices and performance considerations
- Provides specific feedback with line numbers and improvement suggestions

**Review checklist includes:**
- Function design (small, focused, testable)
- Code organization and separation of concerns
- Security (input validation, authentication, CSRF protection)
- Performance (N+1 queries, database optimization)
- Error handling and testing coverage
- Phoenix conventions and template-specific patterns

### `/explain-code`
Explains Phoenix and LiveView code following template patterns.

**Usage:** `/explain-code [what to explain]`

**What it does:**
- Analyzes code structure and explains purpose
- Breaks down complex Phoenix patterns (contexts, LiveViews, schemas)
- Shows data flow and business logic
- Explains authentication, PubSub, and error handling patterns

**Covers:**
- Context pattern for business logic
- LiveView lifecycle and state management
- Schema validation and relationships
- Security considerations and performance implications
- Testing strategies and common patterns

### `/gen-api`
Generates Phoenix API controllers with proper authentication and validation.

**Usage:** `/gen-api [resource description]`

**What it does:**
- Creates API controller with full CRUD operations
- Includes JSON views and proper error handling
- Follows template authentication patterns
- Generates comprehensive tests

**Generates:**
- Controller in `lib/neptuner_web/controllers/api/`
- JSON view module
- Route configuration
- Test file with authentication scenarios
- Proper HTTP status codes and error responses

### `/gen-context`
Generates Phoenix contexts following template conventions.

**Usage:** `/gen-context [context description]`

**What it does:**
- Creates context module with standard functions
- Generates schema with UUID primary keys
- Includes proper validations and associations
- Creates migration files and test factories

**Generates:**
- Context module in `lib/neptuner/`
- Schema module(s) in subdirectory
- Migration file(s)
- Test file and factory definitions
- Standard CRUD functions with proper error handling

### `/gen-liveview`
Generates Phoenix LiveView modules with authentication and styling.

**Usage:** `/gen-liveview [liveview description]`

**What it does:**
- Creates LiveView module with proper lifecycle functions
- Includes authentication patterns and route configuration
- Uses existing core components and DaisyUI styling
- Generates comprehensive LiveView tests

**Generates:**
- LiveView module in `lib/neptuner_web/live/[context]_live/`
- Template file (.html.heex)
- Route configuration
- Test file with authentication scenarios
- Proper form handling and event management

### `/tdd-helper`
Implements Test-Driven Development workflow for Phoenix LiveView features.

**Usage:** `/tdd-helper [functionality description]`

**What it does:**
- Guides through Red-Green-Refactor TDD cycle
- Provides LiveView-specific testing patterns
- Helps write tests first, then implement features
- Includes context, LiveView, and component testing strategies

**TDD workflow:**
1. **Red**: Write failing test describing expected behavior
2. **Green**: Write minimal code to make test pass
3. **Refactor**: Improve code while keeping tests passing

**Testing patterns:**
- Context testing for business logic
- LiveView integration testing
- Component testing
- Event handling and form validation
- Authentication flows

## Usage Tips

1. **Be specific** when describing what you want to generate or review
2. **Provide context** about the business requirements and expected behavior
3. **Use existing patterns** - commands analyze the codebase to follow established conventions
4. **Test-first approach** - especially with `/tdd-helper` for new features
5. **Security focus** - all commands emphasize security best practices and validation

## Examples

```bash
# Review current code changes
/code-review

# Explain authentication code
/explain-code user authentication flow

# Generate API for products
/gen-api product management with CRUD operations

# Create blog context
/gen-context blog with posts and comments

# Build dashboard LiveView
/gen-liveview user dashboard with metrics

# TDD for shopping cart
/tdd-helper shopping cart functionality with add/remove items
```

These commands help maintain consistency across the Phoenix SaaS template while following best practices for security, performance, and maintainability.

## Specialized Agents

The template includes specialized AI agents in `.claude/agents/` that provide expert assistance in specific domains. These agents are automatically invoked by Claude Code when working on relevant tasks.

### Ecto Optimizer (`ecto-optimizer`)
Database specialist for query optimization and performance tuning.

**Expertise:**
- Query performance analysis with EXPLAIN ANALYZE
- Index optimization and N+1 query detection
- Ecto-specific preloading strategies
- Database connection and migration optimization
- PostgreSQL tuning for SaaS workloads

**When used:** Database-related tasks, slow query analysis, migration planning

### SaaS Marketer (`saas-marketer`) 
Marketing specialist for product copy, SEO, and conversion optimization.

**Expertise:**
- Value proposition development and copywriting
- Landing page optimization and CRO
- SEO strategy and keyword research
- Email marketing and nurture sequences
- Competitive positioning and messaging

**When used:** Marketing content creation, landing pages, product copy, growth initiatives

### Prompt Engineer (`prompt-engineer`)
AI prompt engineering specialist for LLM integrations and Claude optimization.

**Expertise:**
- Claude 4 prompt optimization techniques
- SaaS-specific AI integration patterns
- Customer support automation prompts
- Content generation and API documentation
- Prompt testing and iteration strategies

**When used:** Implementing AI features, optimizing prompts, LLM integrations

### UI Expert (`ui-expert`)
UI/UX design specialist focused on modern web design principles.

**Expertise:**
- Layout and spacing optimization
- Visual hierarchy without relying on size
- Design by elimination principles
- Content-first design decisions
- SaaS-specific interaction patterns

**When used:** Interface improvements, visual hierarchy, design system optimization

These agents work seamlessly with the command system to provide specialized expertise while maintaining consistency with the Phoenix SaaS template patterns.