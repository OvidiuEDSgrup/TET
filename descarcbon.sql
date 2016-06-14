select * from ASiSRIA..sesiuniRIA s
select '1BB08F89C62F2'
,* from bt
declare @parxml xml
set @parxml=CONVERT(xml,'<row idAntetBon="575"/>')
exec wDescarcBon @sesiune='1BB08F89C62F2',@parxml=@parxml
