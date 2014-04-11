# Problems
  - Manually writing all the testable paths through an application is tedious, time-consuming, and somewhat error-prone
  - Users will naturally find obscure test paths that even the most experienced QA person might not anticipate
  - How can we leverage the exploratory nature of users to expand a web app's ever-growing need for regression bug coverage?

# Artisan benefits
  - exponentially increases the number of testable paths through an application


==================
Recreating errors seen in the wild can be frustrating, baffling, and sometimes impossible. Combine that fact with the knowledge that new features, and by consequence BUGS, are released frequently means that 100% regression coverage is an unreachable dot on an ever-expanding horizon. With this in mind, we built something to help close this gap.

Initially, we wanted to create a small library to serve as a lightweight black box for web apps. Put simply, this library would store information about user  interactions, such as clicks, typing, and timing between those events, in a JSON format. When an error occurred all that interaction data could be emailed and later replayed exactly as the user had done it to aid in the debugging process.

To keep the project within the scope of these 2 days, we decided to target core features of this black box. Namely, a lightweight approach to capturing user input, and the ability to read & replay that captured input.

While, I've been talking up here Kyle has been using the app with this recording enabled. Now we will show the
