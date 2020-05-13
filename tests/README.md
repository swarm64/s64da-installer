# Unit Testing

To run the unit tests simply install BATS on your local machine:

```git clone https://github.com/bats-core/bats-core.git```

You also need to install 'bats-mock' which does mocking where needed:

```git clone https://github.com/grayhemp/bats-mock.git```

Then make sure that 'bats-mock.bash' is in the 'tests' directory and then it's simply a 
case of running  the bats command (from the repository top-level directory):

```sudo bats tests```

sudo is required because chattr is used in the tests to prevent updates to files to simulate a problem