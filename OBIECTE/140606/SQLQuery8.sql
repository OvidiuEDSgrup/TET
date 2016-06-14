declare @p2 xml
set @p2=convert(xml,N'<row filtruNrDoc=" " tip="TD" datajos="2014/05/01" datasus="2014/05/31"/>')
exec wIaVerificareContabilitate '','<row filtruNrDoc=" " tip="TD" datajos="2014/05/01" datasus="2014/05/31"/>'