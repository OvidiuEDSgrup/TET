create view tpers as
select month(data) as 'Luna',year(data) as 'Anul',personal.nume,lm.denumire,
venit_total,venit_net from net,personal,lm
where net.marca=personal.marca and lm.cod=net.loc_de_munca