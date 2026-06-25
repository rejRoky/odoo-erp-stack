{
    'name': 'Custom Inventory',
    'version': '17.0.1.0.0',
    'category': 'Inventory',
    'summary': 'Warehouse and logistics extensions',
    'description': 'Extends Odoo Inventory with custom warehouse logic and barcode flows.',
    'author': 'erpEBLICT',
    'depends': ['stock', 'purchase', 'stock_picking_batch'],
    'data': [
        'security/ir.model.access.csv',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
