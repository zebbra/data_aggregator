# AGPLv3 Compliance Guide for Data Aggregator

This document explains how to comply with the GNU Affero General Public License v3.0 (AGPLv3) when using, modifying, or distributing Data Aggregator.

## What Makes AGPLv3 Different

The AGPLv3 is similar to the GPLv3 but with an additional requirement: if you modify the software and make it available to users over a network (like a web application), you must provide those users with access to the source code of your modified version.

## For Users Running Data Aggregator

If you are simply using Data Aggregator without modification, you are not required to do anything special for license compliance.

## For Developers Modifying Data Aggregator

### 1. Local Development

For private, personal modifications that are not shared with others or made available over a network, you don't need to distribute your changes.

### 2. Network Use

If you modify Data Aggregator and allow users to interact with it over a network:

- You must make the complete source code of your modified version available to those users
- This includes all modifications you've made
- Users must be clearly notified of how to obtain this source code

### 3. Source Code Availability Options

You can satisfy the source code availability requirement by:

- Adding a prominent link in your application's UI that points to a download location
- Including the full source in your application's "About" or "Legal" section
- Offering to deliver the source code via physical media or download

## For Organizations Distributing Data Aggregator

If you distribute copies of Data Aggregator (modified or unmodified):

1. Include a copy of the AGPLv3 license text
2. Retain all copyright notices in the source code
3. Document any changes you've made to the files
4. Make the complete corresponding source code available to recipients

## Example Compliance Notice

If you run a modified version of Data Aggregator as a service, include a notice like:

> This service runs on a modified version of Data Aggregator, which is licensed under the GNU Affero General Public License v3.0. You can access the source code of our modified version at [URL].

## Common Questions

### Q: Do I need to open-source my entire application that uses Data Aggregator?

A: If your application interacts with Data Aggregator as a separate program (e.g., through APIs), then no. However, any modifications to Data Aggregator itself must be shared under AGPLv3.

### Q: What if I use Data Aggregator as a library or include its code in my application?

A: If you incorporate Data Aggregator code directly into your application, your application may be considered a derivative work and thus subject to AGPLv3, requiring you to open-source the entire application.

### Q: How do we provide source code to users?

A: Include a prominent notice in your UI that tells users where and how they can obtain the source code. This could be a download link or instructions for requesting it.

### Q: Do we need to provide our database content or configuration files?

A: The AGPLv3 requires you to provide source code, not data. However, you should provide sample configuration files and documentation sufficient to run your version.

## License Compatibility

When integrating other libraries with Data Aggregator:

- **Compatible licenses**: GPLv3, LGPLv3, Apache 2.0 (one-way compatibility)
- **Incompatible licenses**: GPLv2 (without the "or later" clause), most proprietary licenses

## Technical Implementation Tips

1. Maintain a clear record of modifications from the original codebase
2. Consider using Git for tracking changes
3. Set up an automated process to generate source archives for distribution
4. Include a copy of the original license and a statement of changes with your distribution

## Legal Notice

This guide provides general information and is not legal advice. For specific legal questions about AGPLv3 compliance, please consult with a legal professional who specializes in open-source licensing.