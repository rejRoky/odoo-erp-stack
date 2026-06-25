{
    'name': 'Custom Accounting',
    'version': '17.0.1.0.0',
    'category': 'Accounting/Accounting',
    'summary': 'Localised accounting rules and report extensions',
    'description': 'Extends Odoo Accounting with business-specific rules and custom reports.',
    'author': 'erpEBLICT',
    'depends': ['account', 'account_accountant'],
    'data': [
        'security/ir.model.access.csv',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
