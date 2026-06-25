{
    'name': 'Custom HR',
    'version': '17.0.1.0.0',
    'category': 'Human Resources',
    'summary': 'HR extensions — custom fields, approval flows, and payroll rules',
    'description': 'Extends Odoo HR and Payroll with organisation-specific configurations.',
    'author': 'erpEBLICT',
    'depends': ['hr', 'hr_payroll', 'hr_attendance', 'hr_leave'],
    'data': [
        'security/ir.model.access.csv',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
