{
    'name': 'Custom API',
    'version': '17.0.1.0.0',
    'category': 'Technical',
    'summary': 'REST/JSON-RPC bridge for external system integration',
    'description': 'Exposes business endpoints for integration with mobile apps and third-party services.',
    'author': 'erpEBLICT',
    'depends': ['web', 'sale', 'stock', 'account'],
    'data': [
        'security/ir.model.access.csv',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
