#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#

# pylint: disable=wrong-import-order
# pylint: disable=missing-module-docstring, missing-class-docstring, missing-function-docstring
# pylint: disable=invalid-name

import unittest

import user.tests.helpers
from user.tests.helpers import random_string

import user.simpleclass

class TestE2ESimpleClass(unittest.TestCase):
    def test_return_first_value(self):
        first_value = random_string()
        second_value = random_string()

        SUT = user.simpleclass.SimpleClass()

        return_value = SUT.return_first_value(first_value, second_value)

        self.assertEqual(return_value, first_value)

if __name__ == '__main__':
    user.tests.helpers.run_tests()
