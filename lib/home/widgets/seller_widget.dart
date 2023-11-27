import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market/model/product.dart';
import 'package:flutter/material.dart';

Future addCategories(String title) async {
  final db = FirebaseFirestore.instance;
  final ref = db.collection('category');
  await ref.add({'title': title});
}

Future<List<Product>> fetchProducts() async {
  final db = FirebaseFirestore.instance;
  final resp = await db.collection('products').orderBy('timestamp').get();
  List<Product> items = [];
  for (var doc in resp.docs) {
    final item = Product.fromJson(doc.data());
    final realItem = item.copyWith(docId: doc.id);
    items.add(item);
  }
  return items;
}

Stream<QuerySnapshot> streamProducts(String query) {
  final db = FirebaseFirestore.instance;
  if (query.isNotEmpty) {
    return db
        .collection('products')
        .orderBy('title')
        .startAt([query]).endAt([query + "\uf8ff"]).snapshots();
  }
  return db.collection('products').orderBy('timestamp').snapshots();
}

class SellerWidget extends StatefulWidget {
  const SellerWidget({super.key});

  @override
  State<SellerWidget> createState() => _SellerWidgetState();
}

class _SellerWidgetState extends State<SellerWidget> {
  TextEditingController textEditingController = TextEditingController();

  update(Product? item) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('products');
    await ref.doc(item?.docId).update(
          item!
              .copyWith(title: 'milk', price: 1000, stock: 10, isSale: false)
              .toJson(),
        );
  }

  delete(Product? item) async {
    final db = FirebaseFirestore.instance;
    await db.collection('products').doc(item?.docId).delete();

    final productCategory = await db
        .collection('products')
        .doc(item?.docId)
        .collection('category')
        .get();
    final foo = productCategory.docs.first;
    final categryId = foo.data()['docId'];
    final bar = await db
        .collection('category')
        .doc(categryId)
        .collection('prodct')
        .where('docId', isEqualTo: item?.docId)
        .get();
    for (var element in bar.docs) {
      element.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            controller: textEditingController,
            leading: Icon(Icons.search),
            onChanged: (value) {
              setState(() {});
            },
            hintText: '상품명 입력',
            onTap: () {},
          ),
          const SizedBox(
            height: 16,
          ),
          ButtonBar(
            children: [
              ElevatedButton(
                onPressed: () async {
                  List<String> categories = [
                    '정육',
                    '과일',
                    '과자',
                    '아이스크림',
                    '유제품',
                    '라면',
                    '생수',
                    '빵/쿠키',
                  ];
                  final ref = FirebaseFirestore.instance.collection('category');
                  final tmp = await ref.get();
                  for (var elemnt in tmp.docs) {
                    await elemnt.reference.delete();
                  }

                  for (var element in categories) {
                    await ref.add({'title': element});
                  }
                },
                child: const Text('카테고리 일괄등록'),
              ),
              ElevatedButton(
                onPressed: () {
                  TextEditingController tec = TextEditingController();
                  showAdaptiveDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: TextField(
                        controller: tec,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (tec.text.isNotEmpty) {
                              await addCategories(tec.text.trim());
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text('등록'),
                        )
                      ],
                    ),
                  );
                },
                child: const Text('카테고리 등록'),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '상품목록',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
                stream: streamProducts(textEditingController.text),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final items = snapshot.data?.docs
                        .map((e) =>
                            Product.fromJson(e.data() as Map<String, dynamic>)
                                .copyWith(
                              docId: e.id,
                            ))
                        .toList();
                    return ListView.builder(
                      itemCount: items?.length,
                      itemBuilder: (context, index) {
                        final item = items?[index];
                        return GestureDetector(
                          onTap: () {
                            print(item?.docId);
                          },
                          child: Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(item?.imgUrl ?? ""),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item?.title ?? '제품 명 ??',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            PopupMenuButton(
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  child: Text('리뷰'),
                                                ),
                                                PopupMenuItem(
                                                  onTap: () => update(item),
                                                  child: Text('수정하기'),
                                                ),
                                                PopupMenuItem(
                                                  child: const Text('삭제'),
                                                  onTap: () => delete(item),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text('${item?.price}원'),
                                        Text(switch (item?.isSale) {
                                          true => '할인 중',
                                          false => '할인 없음',
                                          _ => '??'
                                        }),
                                        Text('재고 수량: ${item?.stock} 개'),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }),
          )
        ],
      ),
    );
  }
}
