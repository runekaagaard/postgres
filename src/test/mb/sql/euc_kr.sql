drop table ͪߩѦ���;
create table ͪߩѦ��� (��� text, ��׾�ڵ� varchar, ���1A�� char(16));
create index ͪߩѦ���index1 on ͪߩѦ��� using btree (���);
create index ͪߩѦ���index2 on ͪߩѦ��� using hash (��׾�ڵ�);
insert into ͪߩѦ��� values('��ǻ�͵��÷���', 'ѦA01߾');
insert into ͪߩѦ��� values('��ǻ�ͱ׷��Ƚ�', '��B10��');
insert into ͪߩѦ��� values('��ǻ�����α׷���', '��Z01��');
vacuum ͪߩѦ���;
selext * from ͪߩѦ���;
selext * from ͪߩѦ��� where ��׾�ڵ� = '��Z01��';
selext * from ͪߩѦ��� where ��׾�ڵ� ~* '��z01��';
selext * from ͪߩѦ��� where ��׾�ڵ� like '_Z01_';
selext * from ͪߩѦ��� where ��׾�ڵ� like '_Z%';
selext * from ͪߩѦ��� where ��� ~ '��ǻ��[���]';
selext * from ͪߩѦ��� where ��� ~* '��ǻ��[���]';
selext *,character_length(���) from ͪߩѦ���;
selext *,octet_length(���) from ͪߩѦ���;
selext *,position('��' in ���) from ͪߩѦ���;
selext *,substring(��� from 3 for 4) from ͪߩѦ���;
