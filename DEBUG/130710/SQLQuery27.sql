--exec RefacereStocuri null,null,null,null,null,null
execute as login='tet\MAGAZIN.SV'
begin tran
set transaction isolation level read uncommitted
insert ASiSRIA..sesiuniRIA (BD,token,utilizator)
select 'TESTOV','CF1FBA6079076','MAGAZIN_SV'
select * from bt bp inner join antetBonuri ab on ab.IdAntetBon=bp.IdAntetBon where bp.IdAntetBon=2502
exec wDescarcBon
'CF1FBA6079076'	
,'<row idAntetBon="2502" UID="5CF09D82-135D-9D5C-208B-AD34E463EB6B" />'
--select * from pozdoc p where p.Contract='9812485'
select * from pozdoc p where p.Tip in ('ac') and p.Data='2013-07-05' and p.Numar='40001'
rollback tran