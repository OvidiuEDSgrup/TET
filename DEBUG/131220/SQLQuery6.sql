set transaction isolation level read committed
begin tran
alter table pozdoc disable trigger all
update pozdoc set idIntrare=null,idIntrareFirma=null
alter table pozdoc enable trigger all
update stocuri set idIntrare=null,idIntrareFirma=null
update istoricstocuri set idIntrare=null,idIntrareFirma=null
commit tran