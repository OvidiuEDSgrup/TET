create procedure [dbo].[GenerareCorectieH]
@datasus datetime, @pmarca char(6), @ploc_de_munca char(9)
as
declare @Ore_luna int, @ncursvnet float, @datajos datetime
Set @Ore_luna = dbo.iauParLN(@datasus,'PS','ORE_LUNA')
Exec Luare_date_par 'PS', 'CURSVNET', 0, @ncursvnet OUTPUT, 0
set @ncursvnet=@ncursvnet/10
set @datajos=dbo.BOM(@datasus)

insert into corectii
(Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
select @datasus,a.marca,a.loc_de_munca,'H-',0,0, convert(int,a.Categoria_salarizare)*@ncursvnet*(convert(float,b.total_ore)/convert(float,@Ore_luna)) from personal a
left outer join (select marca, sum(ore_regie+ore_acord+ore_concediu_de_odihna+ore_obligatii_cetatenesti+ore_intrerupere_tehnologica) as total_ore
from pontaj where data between @datajos and @datasus group by marca) b on b.marca=a.marca
where a.Loc_de_munca between rtrim(isnull(@ploc_de_munca,'')) and rtrim(isnull(@ploc_de_munca,''))+'ZZ' 
and (a.Marca=@pmarca or isnull(@pmarca,'')='') and a.categoria_salarizare<>''
