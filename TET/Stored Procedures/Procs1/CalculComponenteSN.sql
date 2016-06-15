create procedure [dbo].[CalculComponenteSN](@marca char(6),@datajos datetime,@datasus datetime)
as 
begin 

declare @nSalarReferinta int,@nNrTichet int,@nValTichet float,@nOreLuna int
Set @nSalarReferinta=dbo.iauParN('SP','S-NET-REF')
Set @nValTichet=dbo.iauParLN(@datasus,'SP','VALTICHET')
Set @nNrTichet=dbo.iauParLN(@datasus,'SP','NRTICHET')
Set @nOreLuna=dbo.iauParLN(@datasus,'SP','ORE_LUNA')

delete from componente where data=@datasus and marca between (case when @marca<>'' then @marca else '' end) and (case when @marca<>'' then @marca else 'zzzzz' end)
delete from corectii where data=@datasus and marca between (case when @marca<>'' then @marca else '' end) and (case when @marca<>'' then @marca else 'zzzzz' end) 
and marca in (select marca from extinfop where cod_inf like '#'+'%') and tip_corectie_venit='H-'

insert into componente
select @datasus,a.marca,a.cod_inf,a.val_inf,d.procent  
from extinfop a
left outer join catinfop b on b.cod=a.cod_inf 
left outer join extinfop c on c.marca=a.marca and c.cod_inf=a.cod_inf
left outer join extinfop d on d.marca='' and d.cod_inf=a.cod_inf and d.val_inf between (case when b.tip<>'L' then c.val_inf else left(c.val_inf,1) end) and c.val_inf
where (isnull(@marca,'')='' or a.marca=@marca) and a.cod_inf between '#' and '#ZZZZ' and 
((b.tip='L' and a.data_inf between @datajos and @datasus) or (b.tip<>'L' and a.data_inf>=@datajos))
and (a.data_inf=c.data_inf and isnull(a.data_inf,'')<>'')

insert  into componente
(Data, Marca, Cod_comp, Val_comp, Procent) 
select data,marca,'','TICHETE',@nValTichet*@nNrTichet
from componente
where data=@datasus and @nSalarReferinta<>0 
group by data,marca having count(marca)>0 

insert into corectii
(Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
select a.data,a.marca,max(b.loc_de_munca),'H-',0,0,(100+sum((case when a.cod_comp<>'' then @nSalarReferinta*a.procent/100 else 0 end)))*max(c.ore)/@nOreLuna from componente a
left outer join personal b on b.marca=a.marca
left outer join (select marca,sum(ore_regie+ore_acord) as ore from pontaj where data between @datajos and @datasus group by marca) c on c.marca=a.marca
where (isnull(@marca,'')='' or a.marca=@marca) and data=@datasus
group by a.data,a.marca

end
