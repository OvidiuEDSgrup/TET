declare @xtbl xml, @hdoc int, @nrcrt int, @nrcrtmax int, @err nvarchar(max)
/*
alter table ##importXlsTmp add nrcrt int identity(1,1) not null
create unique clustered index id on ##importXlsTmp (nrcrt)
--*/
select @nrcrt=MIN(nrcrt), @nrcrtmax=Max(nrcrt) 
,@nrcrt=null
from ##importXlsTmp 
while isnull(@nrcrt,0)<=@nrcrtmax 
begin
	set @xtbl=
--/*
	(select * from ##importXlsTmp t where @nrcrt is null or t.nrcrt=@nrcrt 
	for XML raw, root('row'))
--*/'<row><row tert="02470320785" dentert="TECNOSOLAR SNC" codfiscal="02470320785" localitate="" denlocalitate="" judet="" denjudet="IT" tara="IT" dentara="ITALIA" adresa="VIA DEL LAVORO, 10 46039 VILLIMPENTA" strada="VIA DEL LAVORO, 10 46039 VILLI" numar="MPENTA" bloc="" scara="" apartament="" codpostal="" telefonfax="" banca="" denbanca="" continbanca="" decontarivaluta="1.000000000000000e+000" nrcrt="5" /></row>'
	begin try
		exec sp_xml_preparedocument @hdoc output,@xtbl
		select * from openxml(@hdoc,'/row/row') with yso_vIaTerti 
		exec sp_xml_removedocument @hdoc 
	end try
	begin catch
		set @err=ERROR_MESSAGE()
		select @nrcrt,@xtbl, @err
		exec sp_xml_removedocument @hdoc 
	end catch
	set @nrcrt=isnull(@nrcrt,@nrcrtmax)+1
end


/*
select soldmaxben,decontarivaluta,discount,tiptert,soldfurn,soldben,* from ##importXlsIniTmp t 
where isnumeric(isnull(decontarivaluta,0))
*isnumeric(isnull(soldmaxben,0))
*isnumeric(isnull(discount,0))
*isnumeric(isnull(tiptert,0))
*isnumeric(isnull(soldfurn,0))
*isnumeric(isnull(soldben,0))
=0
--*/