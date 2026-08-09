#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
''' This module is used to test the development tools.'''

class SimpleClass:
    ''' This class is used to test the development tools.'''
    def return_first_value(self, first_parameter, _second_parameter):
        ''' Return the method's first parameter.'''
        return first_parameter

    def return_second_value(self, _first_parameter, second_parameter):
        ''' Return the method's second parameter.'''
        return second_parameter

if __name__ == "__main__":
    def main():
        """ Run it. """
        first_parameter = 'value 1'
        second_parameter = 'value 2'

        simple_instance = SimpleClass()

        print(simple_instance.return_first_value(first_parameter, second_parameter))

        print(simple_instance.return_second_value(first_parameter, second_parameter))

    main()
