import { NextResponse } from 'next/server';
import admin from 'firebase-admin';

// Initialize Firebase Admin if not already done
if (!admin.apps.length) {
    try {
        let serviceAccount;
        const serviceAccountStr = process.env.FIREBASE_SERVICE_ACCOUNT;

        if (serviceAccountStr) {
            serviceAccount = JSON.parse(serviceAccountStr);
        } else {
            const fs = require('fs');
            const path = 'c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json';
            serviceAccount = JSON.parse(fs.readFileSync(path, 'utf8'));
        }

        if (serviceAccount) {
            if (serviceAccount.private_key) {
                serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
            }
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
    } catch (error) {
        console.error('Error initializing Firebase Admin:', error.message);
    }
}

export async function POST(request) {
    try {
        const { email, password, name, unitCode, role } = await request.json();

        if (!email || !password || !name || !unitCode || !role) {
            return NextResponse.json({ error: 'Faltan campos obligatorios' }, { status: 400 });
        }

        // 1. Create User in Firebase Auth
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name,
        });

        // 2. Create Profile in Firestore
        await admin.firestore()
            .collection('users')
            .doc('admins')
            .collection('members')
            .doc(userRecord.uid)
            .set({
                uid: userRecord.uid,
                email,
                name,
                unitCode,
                role, // 'admin' or 'viewer'
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        return NextResponse.json({ success: true, uid: userRecord.uid });

    } catch (error) {
        console.error('Error creating user:', error.message);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
