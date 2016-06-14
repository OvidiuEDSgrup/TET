SELECT * FROM
    OPENROWSET(
        'SQLOLEDB',
        'Server=10.0.0.10;trusted_connection=yes;Database=TET',
        'set fmtonly off;SET NOCOUNT ON; use tet; exec wIaPozCon @sesiune='''',@parxml=''<row subunitate="1" tip="BK" numar="9830379" data="10/29/2012" tert="1710107161059"/>''') AS tbl_test;