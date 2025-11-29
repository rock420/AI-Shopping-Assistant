# Goal

The goal of this exercise is to create a conversational checkout system that fulfills the criteria listed below:

1. Products can be searched, filtered and viewed through natural language requests
2. Products can be added to and removed from a basket through natural language requests
3. Customers can inquire about their basket contents and see a calculated total price
4. Customers can complete their purchase through the conversation, resulting in an Order
5. Products should have a name, a description, a price and a set of attributes that can be used for filtering through natural language requests
6. Products can be bought more than once
7. Products have limited inventory / quantity available
8. You can expect the checkout system to be in use by up to 5,000 users concurrently

# Deliverables

- Create a database that can support the criteria
- Build a conversational AI interface using React (functional components, hooks, etc.)
- Implement natural language processing to interpret user intents related to shopping
- Design conversation flows that guide users through the shopping experience
- Add tests to validate the intended functionality
- Brief written summary of approach, assumptions, caveats and notes
- The boilerplate repo uses rspec but feel free to use minitest if desired.

Notes:

- The #1 thing we're looking for in this assignment is your ability to write production-quality code under constraints, followed by your ability to communicate your work and incorporate feedback/ideas. If you feel constrained on time in order to get to completion, please let us know. As general guidance, we'd rather have you put in your best work into an incomplete assignment, vs. complete the assignment in a rushed manner.
- Please build a Rails-based REST API as opposed to other options, such as GraphQL. We'd like for the assignment to showcase as much of your own Rails and React work as possible.
- For the styling, use Tailwind CSS framework. Make sure the React code is clean, and it becomes apparent what each HTML element does for a person unfamiliar with the technology. Tip: See Tailwind CSS Core Concepts section of its documentation for more information.
- For the NLP, use the OpenAI API.
- Provide a basic implementation of type checking for React components. Note: the goal should be to provide in-context IDE suggestions more than a robust compile-level safety net.
- Feel free to use seeds to create the required data. No administration is required.
- We recommend that you break down the task into smaller meaningful GitHub issues first.
- For each component of the task, please open a new PR and assign to the engineer you were assigned in the email as the reviewer whenever a PR is ready; do not merge your PRs directly to the main branch. Please keep 3 PRs open at most at any time; and feel free to remind to review your work if there's a delay.
- While we want to explore the potential of conversational interfaces for e-commerce, candidates should consider security and user experience best practices when handling sensitive information (like payment details). We encourage you to use your best judgment in deciding which aspects of the checkout flow should be handled through conversation versus more traditional UI components. Your solution should balance conversational capabilities with appropriate UI elements where needed, and your written summary should explain your reasoning for these design decisions.

### Local Development Setup

#### Prerequisites:

##### General Software Requirements

- Install the latest [Node.js](https://nodejs.org) version. Make sure that [npm](https://www.npmjs.com/) is installed with it as well.
- Install [yarn](https://yarnpkg.com/en/docs/install)
- Install [Ruby version 3.3.6](https://www.ruby-lang.org/en/news/2023/12/25/ruby-3-3-0-released/)
- Install [Postgres](https://postgresapp.com)

##### Installation steps on macOS

- Install [Homebrew](https://brew.sh).
- Install the latest [Node.js](https://nodejs.org) version. Make sure that [npm](https://www.npmjs.com/) is installed with it as well.
- Install [RVM](https://rvm.io/rvm/install)
- Install Ruby 3.3.6 using RVM

  ```
  rvm install 3.3.6
  ```

  To make 3.3.6 as default and current version execute

  ```
  rvm --default use 3.3.6
  ```

- Install PostgreSQL using Homebrew.

  ```
  brew install postgresql
  ```

  Once postgresql is installed to start the server daemon run

  ```
  brew services start postgresql
  ```

- Install Yarn
  ```
  brew install yarn
  ```

#### Bundle Install and Setup DB

```
bundle install
bundle exec rake setup
```

#### Execute yarn

```
bin/yarn
```

#### Spinning up the App

```
./bin/dev
```

Then visit http://localhost:3000

## Use of AI tooling

We do not discourage the use of AI tooling at Circle, even in our code assignments. However, we ask that you are transparent about use of AI tooling and are expected to be able to demonstrate a clear understanding of the code you submit. For this assignment in particular, be prepared to explain how you approached the NLP aspects and conversation design elements.
