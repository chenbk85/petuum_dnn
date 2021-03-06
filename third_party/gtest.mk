# In a nutshell:
#   make gtest-all  - makes everything and run sample test 1.
#   make gtest-build  - build the library in $(LIB).
#   make gtest-clean  - removes all files generated by make.

# Please tweak the following variable definitions as needed by your
# project, except GTEST_HEADERS, which you can use in your own targets
# but shouldn't modify.

# Points to the root of Google Test, relative to where this file is.
# Remember to tweak this if you move this file.
GTEST_DIR = $(THIRD_PARTY)/gtest-1.6.0

# Where to find user code.
USER_DIR = $(GTEST_DIR)/samples

# Temporarily add $(GTEST_DIR)/include to include path. Eventually we'll
# copy them to $(LIB)/include for Petuum applications
CPPFLAGS_GTEST = $(CPPFLAGS) -I$(GTEST_DIR)/include

# Flags passed to the C++ compiler.
CXXFLAGS += -g -Wall -Wextra

# All tests produced by this Makefile.  Remember to add new tests you
# created to the list.
TESTS = sample1_unittest

# All Google Test headers.  Usually you shouldn't change this
# definition.
GTEST_HEADERS = $(GTEST_DIR)/include/gtest/*.h \
                $(GTEST_DIR)/include/gtest/internal/*.h


# =========================================================================
# House-keeping build targets.

# Copy the built .a files and header files to library. Use rsync instead of cp
# to exclude internal gtest's headers.
gtest-build : libgtest.a libgtest_main.a
	cp $(GTEST_DIR)/tmp/*.a $(THIRD_PARTY_INSTALLED)/lib
	cp -rf $(GTEST_DIR)/include/gtest $(THIRD_PARTY_INSTALLED)/include/

# Build + execute the tests as well.
gtest-all : gtest-build $(TESTS)
	$(GTEST_DIR)/tmp/sample1_unittest

gtest-clean :
	rm -rf $(GTEST_DIR)/tmp

.PHONY: gtest-clean

# Usually you shouldn't tweak such internal variables, indicated by a
# trailing _.
GTEST_SRCS_ = $(GTEST_DIR)/src/*.cc $(GTEST_DIR)/src/*.h $(GTEST_HEADERS)


# =========================================================================
# The following object (.o) and archive (.a) rules will build to $(GTEST_DIR)/tmp
gtest-all.o : $(GTEST_SRCS_)
	mkdir -p $(GTEST_DIR)/tmp
	cd $(GTEST_DIR)/tmp;\
	$(CXX) $(CPPFLAGS_GTEST) -I$(GTEST_DIR) $(CXXFLAGS) -c \
            $(GTEST_DIR)/src/gtest-all.cc

gtest_main.o : $(GTEST_SRCS_)
	mkdir -p $(GTEST_DIR)/tmp
	cd $(GTEST_DIR)/tmp;\
	$(CXX) $(CPPFLAGS_GTEST) -I$(GTEST_DIR) $(CXXFLAGS) -c \
            $(GTEST_DIR)/src/gtest_main.cc

libgtest.a : gtest-all.o
	cd $(GTEST_DIR)/tmp;\
	$(AR) $(ARFLAGS) $@ $(GTEST_DIR)/tmp/$^

libgtest_main.a : gtest-all.o gtest_main.o
	cd $(GTEST_DIR)/tmp;\
	$(AR) $(ARFLAGS) $@ $(GTEST_DIR)/tmp/gtest_main.o $(GTEST_DIR)/tmp/gtest-all.o

# =========================================================================
# Builds a sample test.  A test should link with either libgtest.a or
# libgtest_main.a, depending on whether it defines its own main()
# function.

sample1.o : $(USER_DIR)/sample1.cc $(USER_DIR)/sample1.h $(GTEST_HEADERS)
	mkdir -p $(GTEST_DIR)/tmp
	$(CXX) $(CPPFLAGS_GTEST) $(CXXFLAGS) -c $(USER_DIR)/sample1.cc \
	-o $(GTEST_DIR)/tmp/$@

sample1_unittest.o : $(USER_DIR)/sample1_unittest.cc \
                     $(USER_DIR)/sample1.h $(GTEST_HEADERS)
	mkdir -p $(GTEST_DIR)/tmp
	$(CXX) $(CPPFLAGS_GTEST) $(CXXFLAGS) -c $(USER_DIR)/sample1_unittest.cc \
	-o $(GTEST_DIR)/tmp/$@

sample1_unittest : sample1.o sample1_unittest.o libgtest_main.a
	cd $(GTEST_DIR)/tmp;\
	$(CXX) $(CPPFLAGS_GTEST) $(CXXFLAGS) -lpthread $^ -o $(GTEST_DIR)/tmp/$@
