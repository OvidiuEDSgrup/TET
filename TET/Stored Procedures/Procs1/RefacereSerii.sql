--***
create procedure RefacereSerii @cGestiune char(20), @cCod char(20), @dData datetime
as

if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
begin
		raiserror('Accesul este restrictionat pe anumite gestiuni! Nu este permisa operatia in aceste conditii!',16,1)
		return
end

if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
end

delete serii
where (isnull(@cGestiune,'')='' or serii.gestiune=@cGestiune)
and (isnull(@cCod,'')='' or serii.cod=@cCod)

insert serii
(Subunitate, Tip_gestiune, Gestiune, Cod, Cod_intrare, Serie, Stoc_initial, Intrari, Iesiri, Stoc)
select 
a.subunitate, a.tip_gestiune, a.gestiune, a.cod, a.cod_intrare, a.serie, 
a.stoc_initial, a.intrari, a.iesiri, a.stoc
from dbo.fSeriiCen(@dData, @cCod, @cGestiune, null, null, 1, 1, 1, 1, '', '') a
where not exists (select 1 from serii s where s.subunitate=a.subunitate and s.tip_gestiune=a.tip_gestiune and s.gestiune=a.gestiune and s.cod=a.cod and s.cod_intrare=a.cod_intrare and s.serie=a.serie)
