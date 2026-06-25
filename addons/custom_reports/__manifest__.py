{
    'name': 'Custom Reports',
    'version': '17.0.1.0.0',
    'category': 'Technical',
    'summary': 'Custom PDF and XLSX report templates',
    'description': 'Branded PDF reports and Excel exports for invoices, orders, and stock.',
    'author': 'erpEBLICT',
    'depends': ['account', 'sale', 'purchase', 'stock'],
    'data': [
        'security/ir.model.access.csv',
        'report/report_invoice.xml',
        'report/report_sale_order.xml',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
